geolib = require "geolib"

@include = ->
  unless @store?
    console.log "Err no data store".red
    process.exit(1);

  @twitter_client = require('twitter-api').createClient()
  @twitter_client.setAuth @conf.twitter.key,
    @conf.twitter.secret
    @conf.twitter.token_key
    @conf.twitter.token_secret
  console.log "client: ", 

  @twitter_client.get 'account/verify_credentials', 
    skip_status: true
    ( user, error, status ) ->
      console.log if user then 'Authenticated as @'+user.screen_name else 'Not authenticated'

  check_tweet = (status) =>
    geo = 
      if status.geo
        geo: status.geo
      else if status.user.location
        user: status.user.location

    if geo?.geo or status.entities.urls?.length or status.entities.media?.length or 
      status.entities.hashtags?.length

        console.log status.user.name.magenta, status.lang.green, status.text, geo, 
          _(status.entities.hashtags).pluck("text").join(", ").yellow
        console.log _(status.entities).keys()


        if status.entities.hashtags?.length or status.text.match(new RegExp("#{@conf.city}", "i"))
          if status.entities.media?.length
            console.log status.entities.media[0].sizes.thumb
          @send_post 
            author: 
              username: "#{status.user.name} (#{status.user.screen_name})"
              link: "http://twitter.com/" + status.user.screen_name
            content: status.text
            hashtags: _(status.entities.hashtags).pluck("text")
            post_date: (new Date(status.created_at)).getTime()
            poi: if geo?.geo
              name: "#{status.user.screen_name} pos"
              coord: geo.geo.coordinates


  @twitter_client.get "search/tweets",
    count: 100
    q: @conf.city
    include_entities: true
    geocode: @conf.geo.location.latitude + "," + @conf.geo.location.longitude + ",15km"
    ( result, error, status) ->
      console.log "Tweets Found : ", result.statuses.length, error, status
      for status in result.statuses
        check_tweet status

  @twitter_client.stream "statuses/filter", data = {
      #delimited: "length"
      # City term
      #track: @conf.city
      # Location
      locations: @conf.geo.bbox.sw.lng + "," + @conf.geo.bbox.sw.lat + "," +
        @conf.geo.bbox.ne.lng + "," + @conf.geo.bbox.ne.lat
    },
    (json) =>
      status = JSON.parse(json)
      console.log "TEXT".red, status.text
      if status.geo?.coordinates
        console.log status.geo?.coordinates
        if geolib.isPointInside(
          {
            latitude: status.geo?.coordinates[0]
            longitude: status.geo?.coordinates[1]
          }
          [
            {
              latitude: @conf.geo.bbox.sw.lat
              longitude: @conf.geo.bbox.sw.lng
            }
            {
              latitude: @conf.geo.bbox.sw.lat
              longitude: @conf.geo.bbox.ne.lng
            }
            {
              latitude: @conf.geo.bbox.ne.lat
              longitude: @conf.geo.bbox.ne.lng
            }
            {
              latitude: @conf.geo.bbox.ne.lat
              longitude: @conf.geo.bbox.sw.lng
            }
          ]
        )
          console.log "Inside bbox".green, status.geo?.coordinates
          check_tweet status
        else
          console.log "Not inside bbox".red, status.geo?.coordinates
  console.log "streaming on ".yellow, data
