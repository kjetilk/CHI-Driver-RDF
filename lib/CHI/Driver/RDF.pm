package CHI::Driver::RDF;
use Moo;
use strict;
use warnings;
use RDF::Trine qw(iri literal);
use DateTime;
use DateTime::Format::W3CDTF;
use Carp;

extends 'CHI::Driver';

has 'model' => ( is => 'ro', 
						  isa => 'RDF::Trine::Model',
						  required=> 1);


sub fetch {
	my ( $self, $key ) = @_;
	return $self->model->get_statements(undef, undef, undef, iri("urn:chicache:body:$key"));
}

sub store {
	my ( $self, $key, $data, $expires_in ) = @_;
	my $now = DateTime->now;
	my $model = $self->model;
	my $httpns = RDF::Trine::Namespace->new('http://www.w3.org/2011/http#');
	my $metadata_graph = iri("urn:chicache:header:metadata");
	$model->begin_bulk_ops;
	$model->add_statement(iri("urn:chicache:response:$key"), $httpns->header, iri("urn:chicache:header:expiry:$key"), $metadata_graph);
	$model->add_statement(iri("urn:chicache:header:expiry:$key"), $httpns->fieldName, literal('Expires'), $metadata_graph);
	my $expiry = $now->add(second => $expires_in);
	my $w3c = DateTime::Format::W3CDTF->new;
	$model->add_statement(iri("urn:chicache:header:expiry:$key"), $httpns->fieldValue, 
								 literal($w3c->format_datetime($expiry), undef,
											'http://www.w3.org/2001/XMLSchema#dateTime'), $metadata_graph);
	
	$model->add_statement(iri("urn:chicache:response:$key"), $httpns->body, iri("urn:chicache:body:$key"), $metadata_graph);
	foreach my $triple (@$data) {
		croak 'Only triples are supported for caching' unless (ref($triple) eq 'RDF::Trine::Statement');
		$model->add_statement($triple, iri("urn:chicache:body:$key"));
	}
	$model->end_bulk_ops;
}

sub remove {
	my ( $self, $key ) = @_;
	my $model = $self->model;
	$model->remove_statements(iri("urn:chicache:response:$key"), undef, undef, undef);
	$model->remove_statements(iri("urn:chicache:header:expiry:$key"), undef, undef, undef);
	$model->remove_statements(undef, undef, undef, iri("urn:chicache:body:$key"));
}

sub clear {
    my $self = shift;
	 $self->model->nuke;
}

sub get_keys {
    my $self = shift;
	 my @keys;
	 my $httpns = RDF::Trine::Namespace->new('http://www.w3.org/2011/http#');
	 my $urns = $self->model->get_statements(undef, $httpns->body, undef, iri("urn:chicache:header:metadata"));
	 foreach my $triple (@{$urns}) {
		 my ($key) = $triple->object->uri_value =~ m/urn:chicache:response:(\S+)$/;
		 push(@keys, $key);
	 }
	 return @keys;
}

