# CallnumberCollation

An attempt to do the dumbest thing possible that will still give decent
callnumber sorting.


## Usage

### Command line

```bash
>  callnumber_normalized QA142.77 C5 .d66 1990    v.1
qa142.77 .c5 d66 1990 v.1

> callnumber_collation QA142.77 C5 .d66 1990 v.1
qa   3142.77 c5 d66 1990  v.1
```

### In code

```ruby
require 'callnumber_collation'

c = CallnumberCollation::LC.new("QA142.77 C5 .d66 1990 v.1")
=> #<CallnumberCollation::LC:0x00007fb7994bf1b0
  # @original="qa142.77 c5 .d66 1990 v.1", 
  # @letters="qa", @digits="142", @decimal="77", 
  # @cutter_stuff="c5 .d66", @year="1990", 
  # @rest=" v.1", @valid=true>
c.valid? #=> true
c.letters #=> qa
c.normalized #=> "qa142.77 .c5 d66 1990 v.1"
c.collation_key #=> "qa   3142.77 c5 d66 1990 v.1"
c.collation_key_base #=> "qa   3142.77 c5 d66 1990" (iffy)

# Use the collation key to sort
sorted = my_raw_callnumbers.map{|cn| CallnumberCollation::LC.new(cn)}.
  sort{|a,b| a.collation_key <=> b.collation_key}

```

## LC (Library of Congress)

This is an attempt to do as little as possible to get collation keys
(for alphbetization) for call numbers.

The only real limits imposed are that:
  * It must start with a letter
  * The inititial letter sequence must be 5 chars or less
  * The letter(s) must be followed by a number

The only real transformations are:
  * Whitespace collapsing/stripping
  * Padding the initial letters to five characters
  * Prepending the length of the initial digits to those digits.
    * 45 becomes 245; 123 becomes 3123
    * This provides correct alphabetical sorting without messing around
      with zero-padding or anything
  * Eliminate dots before cutters

### collation_key_base

There is a minor attempt to determine what "all the other stuff" (probably
enumchron), and then report everything up until that point as the 
`collation_key_base`. This might be useful for de-duping multiple 
copies/volumes/etc. but isn't very smart and should be used with 
caution. Test with your own data!

## Non-matching callnumbers

Anything that doesn't match will return `false` for `#valid?`. In this case:
  * The "normalized" version is simple downcased and whitespace-collapsed
  * The collation_key is the same as the normalized version

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/billdueber/callnumber_collation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
