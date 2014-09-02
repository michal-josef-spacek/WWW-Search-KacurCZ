package WWW::Search::KacurCZ;

# Pragmas.
use base qw(WWW::Search);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use LWP::UserAgent;
use Readonly;
use Text::Iconv;
use Web::Scraper;

# Constants.
Readonly::Scalar our $MAINTAINER => 'Michal Spacek <skim@cpan.org>';
Readonly::Scalar my $KACUR_CZ => 'http://kacur.cz/';
Readonly::Scalar my $KACUR_CZ_ACTION1 => '/search.asp?doIt=search&menu=675&kategorie=&nazev=&rok=&dosearch=Vyhledat';

# Version.
our $VERSION = 0.01;

# Setup.
sub native_setup_search {
	my ($self, $query) = @_;
	$self->{'_def'} = scraper {
		process '//div[@class="productItemX"]', 'books[]' => scraper {
			process '//div/h3/a', 'title' => 'TEXT';
			process '//div/h3/a', 'detailed_link' => '@href';
			process '//img', 'image' => '@src';
			process '//p', 'author_publisher[]' => 'TEXT';
			process '//span[@class="price"]', 'price' => 'TEXT';
			return;
		};
		return;
	};
	$self->{'_query'} = $query;
	return 1;
}

# Get data.
sub native_retrieve_some {
	my $self = shift;

	# Query.
	my $i1 = Text::Iconv->new('utf-8', 'windows-1250');
	my $query = $i1->convert(decode_utf8($self->{'_query'}));

	# Get content.
	my $ua = LWP::UserAgent->new(
		'agent' => "WWW::Search::KacurCZ/$VERSION",
	);
	my $response = $ua->get($KACUR_CZ.$KACUR_CZ_ACTION1."&autor=$query");

	# Process.
	if ($response->is_success) {
		my $i2 = Text::Iconv->new('windows-1250', 'utf-8');
		my $content = $i2->convert($response->content);

		# Get books structure.
		my $books_hr = $self->{'_def'}->scrape($content);

		# Process each book.
		foreach my $book_hr (@{$books_hr->{'books'}}) {
			_fix_url($book_hr, 'detailed_link');
			_fix_url($book_hr, 'image');
			$book_hr->{'author'}
				= $book_hr->{'author_publisher'}->[0];
			$book_hr->{'author'} =~ s/\N{U+00A0}$//ms;
			$book_hr->{'publisher'}
				= $book_hr->{'author_publisher'}->[1];
			$book_hr->{'publisher'} =~ s/\N{U+00A0}$//ms;
			delete $book_hr->{'author_publisher'};
			($book_hr->{'old_price'}, $book_hr->{'price'})
				= split m/\s*\*\s*/ms, $book_hr->{'price'};
			push @{$self->{'cache'}}, $book_hr;
		}
	}

	return;
}

# Fix URL to absolute path.
sub _fix_url {
	my ($book_hr, $url) = @_;
	if (exists $book_hr->{$url}) {
		$book_hr->{$url} = $KACUR_CZ.$book_hr->{$url};
	}
	return;
}

1;

__END__
