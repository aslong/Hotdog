$ ->


  ##############################
  ##   Tweet Representation   ##
  ##############################
  source  = $("#tweet-template").html()
  tweet_template = Handlebars.compile( source )

  display_tweet = ( tweet ) ->
    $tweets = $('#tweets')
    $( '#'+tweet.tweet_id ).remove()
    html = tweet_template( tweet )
    if tweet.position == 1
      $tweets.prepend( html )
    else
      $tweets.find('.tweet').eq( tweet.position - 2 ).after( html )
    prune_tweets()

  prune_tweets = ->
    $('#tweets .tweet').each ( index, el ) ->
      if index > 9
        $(el).remove()
  ##############################


  ##############################
  ##   Socket Communication   ##
  ##############################
  socket = io.connect( 'http://localhost:5000' )

  socket.on 'initialize', ( data ) ->
    
    $tweets = $('#tweets')
    $.each data, ( index, tweet ) ->
      html = tweet_template( tweet )
      $tweets.append( html )

  socket.on 'tweet', ( tweet ) ->
    if listening
      display_tweet( tweet )
  ##############################


  #######################
  ##   Form Handling   ##
  #######################
  $form = $('form')
  $input = $form.find( 'input[type=text]' )
  $button = $form.find( 'button' )

  listening = false
  $form.on 'submit', ->
    $('#tweets').html( '' )

    listening = true
    data =
      query: $input.val()
    socket.emit( 'query', data )
    
    $button.text( 'Streaming...' )
    $button.addClass( 'btn-success' )

    false

  $input.on 'keyup', ( e ) ->
    return unless e.keyCode == 8
    listening = false
    $button.text( 'Stream' )
    $button.removeClass( 'btn-success' )
    $button.addClass( 'btn-primary' )
    $('#tweets').text( '' )
  #######################


