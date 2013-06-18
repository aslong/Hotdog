(function() {

  $(function() {
    var $button, $form, $input, display_tweet, listening, prune_tweets, socket, source, tweet_template;
    source = $("#tweet-template").html();
    tweet_template = Handlebars.compile(source);
    display_tweet = function(tweet) {
      var $tweets, html;
      $tweets = $('#tweets');
      $('#' + tweet.tweet_id).remove();
      html = tweet_template(tweet);
      if (tweet.position === 1) {
        $tweets.prepend(html);
      } else {
        $tweets.find('.tweet').eq(tweet.position - 2).after(html);
      }
      return prune_tweets();
    };
    prune_tweets = function() {
      return $('#tweets .tweet').each(function(index, el) {
        if (index > 9) {
          return $(el).remove();
        }
      });
    };
    socket = io.connect('http://localhost:5000');
    socket.on('initialize', function(data) {
      var $tweets;
      $tweets = $('#tweets');
      return $.each(data, function(index, tweet) {
        var html;
        html = tweet_template(tweet);
        return $tweets.append(html);
      });
    });
    socket.on('tweet', function(tweet) {
      if (listening) {
        return display_tweet(tweet);
      }
    });
    $form = $('form');
    $input = $form.find('input[type=text]');
    $button = $form.find('button');
    listening = false;
    $form.on('submit', function() {
      var data;
      $('#tweets').html('');
      listening = true;
      data = {
        query: $input.val()
      };
      socket.emit('query', data);
      $button.text('Streaming...');
      $button.addClass('btn-success');
      return false;
    });
    return $input.on('keyup', function(e) {
      if (e.keyCode !== 8) {
        return;
      }
      listening = false;
      $button.text('Stream');
      $button.removeClass('btn-success');
      $button.addClass('btn-primary');
      return $('#tweets').text('');
    });
  });

}).call(this);
