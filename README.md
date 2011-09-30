## Simple HTTP client using Typheous, derived from the Riak client

### Notes

It works for us, handles a few billion operations a day. It hasn't been polished for the public yet. I wanted to get
it up on RubyGems quickly: I was fighting the consquences of Ruby's global mutable namespaces combined with the 
unfortunate choice of naming our library Http and suddenly fighting with http_parser.rb for class Http vs module Http.


### Authors

* Coda Hale
* Benjamin Kudria
* Jordi Bunster
* Matthew Knopp
* Mohammed Rafiq
* Ryan Kennedy
