package CHI::Driver::MyDriver;
use Moo;
use strict;
use warnings;
use RDF::Trine qw(iri literal);
use DateTime;
use DateTime::Format::W3CDTF;
use Carp;

extends 'CHI::Driver';

has 'model' => ( is => 'ro', isa => 'RDF::Trine::Model', builder => '_build_model' );

has 'httpns' => (is ='ro', isa => 'RDF::Trine::Namespace', 
					  default => RDF::Trine::Namespace->new('http://www.w3.org/2011/http#'));


sub _build_model {
	return RDF::Trine::Model->temporary_model;
}


sub fetch {
    my ( $self, $key ) = @_;
	 return $self->model->get_statements(undef, undef, undef, iri("urn:chicache:body:$key"));
}
 
sub store {
    my ( $self, $key, $data, $expires_in ) = @_;
	 my $now = DateTime->now;
	 $self->model->begin_bulk_ops;
	 $self->model->add_statement(iri("urn:chicache:response:$key"), $httpns->header, iri("urn:chicache:header:expiry:$key"))
	 $self->model->add_statement(iri("urn:chicache:header:expiry:$key"), $httpns->fieldName, literal('Expires'));
	 my $expiry = $now->add(second => $expires_in);
	 my $w3c = DateTime::Format::W3CDTF->new;
	 $self->model->add_statement(iri("urn:chicache:header:expiry:$key"), $httpns->fieldValue, 
										  literal($w3c->format_datetime($expiry), undef,
													'http://www.w3.org/2001/XMLSchema#dateTime');

	 $self->model->add_statement(iri("urn:chicache:response:$key"), $httpns->body, iri("urn:chicache:body:$key"))
	 foreach my $triple (@$data) {
		 croak 'Only triples are supported for caching' unless (ref($triple) eq 'RDF::Trine::Statement');
		 $self->model->add_statement($triple, iri("urn:chicache:body:$key"))
	 }
	 $self->model->end_bulk_ops;
	 
}
 
sub remove {
    my ( $self, $key ) = @_;
 
}
 
sub clear {
    my ($self) = @_;
 
}
 
sub get_keys {
    my ($self) = @_;
 
}
 
sub get_namespaces {
    my ($self) = @_;
 
}
