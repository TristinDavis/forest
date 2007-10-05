
package Forest::Tree::Roles::JSONable;
use Moose::Role;

# TODO:
# convert this to use JSON::Any
# - SL
use JSON::Syck ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

requires 'as_json';

no Moose; 1;

__END__

=pod

=head1 METHODS

=over 4

=item B<as_json (?%options)>

Return a JSON string of the invocant. Takes C<%options> 
parameter to specify the way the tree is to be dumped. 

=back

=cut