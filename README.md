## Simple HTTP client using Typheous, derived from the Riak client

### Notes

It works for us, handles a large number operations a day. It hasn't been polished for the public yet. I wanted to get
it up on RubyGems quickly: I was fighting the consquences of Ruby's global mutable namespaces combined with the 
unfortunate choice of naming our library Http and suddenly fighting with http_parser.rb for class Http vs module Http.


### Authors

* Coda Hale
* Benjamin Kudria
* Brian Morton
* Jordi Bunster
* Matthew Knopp
* Mohammed Rafiq
* Ryan Kennedy
* Vidit Drolia
* Vivek Aggarwal
* Sean Wolfe

### References

* Ruby Riak Client: https://bitbucket.org/basho/riak-ruby-client/src

### Deploying to RubyGems

1. Bump version in `VERSION` and `zephyr.gemspec`.
2. Run `bundle` to update gem in Gemfile.lock.
3. Commit changes with version update.
4. Tag the release
  * `git tag -a v1.x.x`
	* `git push --tags`
5. Build the gem: `gem build zephyr.gemspec`
6. Push to rubygems: `gem push zephyr-1.2.2.gem`
