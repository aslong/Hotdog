###
  Configure Twitter Client
###
auth =
  consumer_key: process.env.TWITTER_CONSUMER_KEY
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET
  access_token_key: process.env.TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.TWITTER_ACCESS_SECRET
twitter = new require('ntwitter')( auth )

###
  Connect to MongoDB
###
mongodb = require( 'mongodb' )
mongo_server = new mongodb.Server( '127.0.0.1', 27017, {w:1} )

new mongodb.Db( 'hotdog', mongo_server, {} ).open ( error, client ) ->
  throw error if error

  tweets = new mongodb.Collection( client, 'tweets' )
  
  ###
    Bind Socket.io to 5000
  ###
  io = require('socket.io').listen( 5000 )
  io.sockets.on 'connection', ( socket ) ->

    ###
      Listen for query events
    ###
    socket.on 'query', ( data ) ->

      ###
        Send Stored Tweets
      ###
      cursor = tweets.find( { query: data.query } )
      cursor.sort( { count: -1 } )
      cursor.limit( 10 )
      cursor.toArray ( err, docs ) ->
        socket.emit( 'initialize', docs )

      ###
        Open Twitter Stream
      ###
      twitter.stream 'statuses/filter', { track: data.query }, ( stream ) ->

        console.log( 'Now listening for "' + data.query + '"' )

        stream.on 'data', ( twitter_data ) ->

          ###
            Ignore if this is not a retweet
          ###
          retweeted = twitter_data.retweeted_status
          return unless retweeted

          ###
            Upsert the data into Mongo
          ###
          tweet =
            tweet_id: retweeted.id_str
            author: retweeted.user.screen_name
            tweet: retweeted.text
            query: data.query

          update =
            $set:
              count: retweeted.retweet_count
            $push:
              retweeters: twitter_data.user.screen_name

          tweets.update( tweet, update, { upsert: true } )

          ###
            Retrieve the top 10
          ###
          cursor = tweets.find( { query: data.query }, [ 'tweet_id' ] )
          cursor.sort( { count: -1 } )
          cursor.limit( 10 )
          cursor.toArray ( err, docs ) ->

            ###
              If it's not in the top ten, don't send to client
            ###
            docs = docs.map ( doc ) ->
              doc.tweet_id
            position = docs.indexOf( retweeted.id_str )
            return if position == -1

            ###
              Send the tweet to the client
            ###

            tweet.count = update.$set.count
            tweet.position = position + 1
            socket.emit( 'tweet', tweet )

