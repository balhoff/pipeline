PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
DELETE { 
  ?sub rdfs:label ?label .
} 
INSERT {
  ?sub rdfs:label ?newlabel .
}
WHERE {
  ?sub rdfs:label ?label .
  BIND(CONCAT(?label, " (zebrafish)"^^xsd:string) AS ?newlabel)
  FILTER(STRSTARTS(STR(?sub), "http://purl.obolibrary.org/obo/ZFA_"))
}
