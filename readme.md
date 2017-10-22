# Fitl

Experimental code for examining bot action in Fire in the Lake.



### Testing

Setting up the code to run correctly is a bit outre as it's
using ActiveRecord outside of a Rails environment. The following
seems to work for doing the migrations:

* `rake db:environment:set`
* `rake db:test:prepare`

Don't forget to run `rake db:migrate`.

### Development


## Air Lift

I'm reading a discrepancy in the Air Lift example. Initially, two US
Troops are designated available in Quang Tri, leaving 2 US Troops and
1 US Irregular behind to activate the 3 NVA guerrillas. Later, this
US Irregular is supposed to Air Lift out, which doesn't make any sense
to me. This implementation leaves the Irregulars in the space by default
to activate. It would be possible to either always airlift the
Irregulars out, or Air Lift them according to some as yet unspecified
criterion, that can be implemented later.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

