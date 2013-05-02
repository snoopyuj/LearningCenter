# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->

  $("#post_area").hide()

  $("#post_button").click ->
    $("#post_area").show()

  $("#post_to_fb").click ->
    alert($("#post_content").val())
    $.ajax
     type: "POST"
     url: "/facebook_activity/post_wall"
     data:
       post_content: $("#post_content").val()
       datatype: "json"
       success: ->
         alert("success")
         $("#post_area").hide()
