Elearning::Application.routes.draw do
  #RESTful
    resources :courses

    get '/course/info/:id' => 'courses#info', :as => 'info'
    match 'course/parse_course_tree' => 'courses#parse_course_tree', :as => 'parse_course_tree'
    match 'course/parse_course_tree_general_version' => 'courses#parse_course_tree_general_version', :as => 'parse_course_tree_general_version'
    get '/course/download_course_list' => 'courses#download_course_list', :as => 'download_course_list'
    post '/course/upload_course_list/' => 'courses#upload_course_list', :as => 'upload_course_list'
    match 'course/view_course/:id' => 'courses#view_course', :as => 'view_course'
    match '/course/calculate_similarity' => 'courses#calculate_similarity', :as => 'calculate_similarity'
    match '/course/progress_monitor_by_course' => 'courses#progress_monitor_by_course', :as => 'progress_monitor_by_course'
    match '/course/progress_monitor_by_user' => 'courses#progress_monitor_by_user', :as => 'progress_monitor_by_user'

  #for omniauth
    resources :authentications

    match '/auth/facebook/callback' => 'authentications#create'

  #Devise
    devise_for :users, :controller => { :registrations => 'registrations'}
    #root for method after_sign_out
    root :to => "courses#index"

  #fb_graph
    match 'facebook_activity/send_data_to_3D' => 'facebook_activity#send_data_to_3D', :as => 'send_data_to_3D'

    resources :facebook_activity
    
    post '/facebook_activity/post_wall' => 'facebook_activity#post_wall', :as => 'post_wall'
    post 'facebook_activity/action_wall' => 'facebook_activity#action_wall', :as => 'action_wall'
    match 'facebook_activity/get_fb_friends' => 'facebook_activity#get_fb_friends', :as => 'get_fb_friends'
    match 'facebook_activity/send_data_to_3D' => 'facebook_activity#send_data_to_3D', :as => 'send_data_to_3D'

  #for recommendation system
    resources :recommendation
    
    match '/recommendation/friend_recommendation' => 'recommendation#friend_recommendation', :as => 'friend_recommendation'
    match '/recommendation/friend_recommendation_in_category' => 'recommendation#friend_recommendation_in_category', :as => 'friend_recommendation_in_category'
    match '/recommendation/friend_recommendation_in_course' => 'recommendation#friend_recommendation_in_course', :as => 'friend_recommendation_in_course'
    match '/recommendation/ask_recommendation_in_category' => 'recommendation#ask_recommendation_in_category', :as => 'ask_recommendation_in_category'
    match '/recommendation/ask_recommendation_in_course' => 'recommendation#ask_recommendation_in_course', :as => 'ask_recommendation_in_course'

    match '/recommendation/course_recommendation' => 'recommendation#course_recommendation', :as => 'course_recommendation'
    match '/recommendation/course_recommendation_calculation' => 'recommendation#course_recommendation_calculation', :as => 'course_recommendation_calculation'

    

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  #match ':controller(/:action(/:id))(.:format)'
end
