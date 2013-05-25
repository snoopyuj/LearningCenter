# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->

  $("#select_category").hide()
  $("#select_course").hide()
  $("#recommendation_in_category").hide()
  $("#recommendation_in_course").hide()

  $("#select_mode").change ->
    if $("#select_mode").val() is "category"
      $("#select_category").show()
      $("#recommendation_in_category").show()
    else
      $("#select_category").show()	

  $("#select_category").change ->
    if $("#select_mode").val() is "course"
      category = $("#select_category :selected").text()
      options = $("#select_course").find("optgroup[label="+category+"]").html()
      $("#select_course").html(options)
      $("#select_course").show()
      $("#recommendation_in_course").show()

  $("#recommendation_in_category").click -> 
    $.ajax
      type: "POST"
      url: "/recommendation/friend_recommendation_in_category"
      data:
        select_category: $("#select_category").val()
        datatype: "script"
      success: ->
        $("#intro_word").hide()


  $("#recommendation_in_course").click ->
    $.ajax
      type: "POST"
      url: "/recommendation/friend_recommendation_in_course"
      data:
        select_course: $("#select_course").val()
        datatype: "script"
      success: ->
        $("#intro_word").hide()

  $("#course_recommend_submit_button").click ->      
    $.ajax
      type: "POST"
      url: "/recommendation/course_recommendation_calculation"
      data:
        select_category: $("#course_recommend_select_category").val()
        datatype: "script"
      success: ->
        $("#intro_word").hide()





