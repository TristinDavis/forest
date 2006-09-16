
package Forest::Tree;
use Moose;

our $VERSION = '0.0.1';

has 'node' => (is => 'rw'); # isa => Any ,... which amounts to a NOOP

has 'uid'  => (
    is      => 'rw', 
    isa     => 'Value',
    lazy    => 1,
    default => sub { ($_[0] =~ /\((.*?)\)$/)[0] }
);

has 'parent' => (
    reader      => 'parent',
    writer      => '_set_parent',   
    predicate   => 'has_parent', 
    isa         => 'Forest::Tree',  
    is_weak_ref => 1,  
    handles     => { 
        'add_sibling'       => 'add_child',
        'get_sibling_at'    => 'get_child_at',
        'insert_sibling_at' => 'insert_child_at',
    },       
);

has 'children' => (
    is  => 'rw',
    isa => 'ArrayRef',
);

## informational 

sub is_root { !(shift)->has_parent      }
sub is_leaf { (shift)->child_count == 0 }

## depth 

sub depth { ((shift)->parent || return -1)->depth + 1 }

## child management

sub add_child {
    my ($self, $child) = @_;
    (blessed($child) && $child->isa('Forest::Tree'))
        || confess "Child parameter must be a Forest::Tree not ($child)";
    $child->_set_parent($self);
    push @{$self->children} => $child;
    $self;
}

sub insert_child_at {
    my ($self, $index, $child) = @_;
    (blessed($child) && $child->isa('Forest::Tree'))
        || confess "Child parameter must be a Forest::Tree not ($child)";    
    $child->_set_parent($self);
    splice @{$self->children}, $index, 0, $child;    
}

sub get_child_at {
    my ($self, $index) = @_;
    $self->children->[$index];
}

sub child_count { scalar @{(shift)->children} };

## traversal

sub traverse {
    my ($self, $func) = @_;
    (defined($func)) 
        || confess "Insufficient Arguments : Cannot traverse without traversal function";
    (ref($func) eq "CODE") 
        || die "Incorrect Object Type : traversal function is not a function";
    foreach my $child (@{$self->children}) { 
        $func->($child);
        $child->traverse($func);
    }    
}


# NOTE:
# we are basically inlining the 
# constructor here, and caching
# all our important bits, this 
# speeds up building large trees 
# considerably.
__PACKAGE__->meta->make_immutable(inline_accessors => 0);

no Moose;

__END__

=pod

=cut