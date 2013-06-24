ACTIVATE = "grenoble"
module.exports = _(
  switch ACTIVATE.toLowerCase()
    when "paris"
      city: "Paris"
      geo: 
        location:
          latitude: 48.8742 #45.1911576
          longitude:  2.3470 #5.7186758
        bbox:
          ne:
            lat: 48.9021449
            lng: 2.4699208
          sw:
            lat: 48.815573
            lng: 2.224199
    when "grenoble"
      city: "Grenoble"
      geo: 
        location:
          latitude: 45.1911576
          longitude: 5.7186758
        bbox:
          ne:
            lat: 45.2143261
            lng: 5.753081
          sw:
            lat: 45.154005
            lng: 5.678003899999999
  ).defaults
    within: "20km"
    twitter: require "./twitter.coffee"
    foursquare: require "./fq.coffee"