Elearning::Application.routes.draw do
  #RESTful
    resources :courses

    #use get to handle the url like /courses/info/id
    get '/course/info/:id' => 'courses#info', :as => 'info'
    #download_course_list
    get '/course/download_course_list' => 'courses#download_course_list', :as => 'download_course_list'
    #upload_course_list
    post '/course/upload_course_list/' => 'courses#upload_course_list', :as => 'upload_course_list'
    #view_course
    match 'course/view_course/:id' => 'courses#view_course', :as => 'view_course'
    #progress_monitor_by_course
    match 'course/progress_monitor_by_course' => 'courses#progress_monitor_by_course', :as => 'progress_monitor_by_course'
    #progress_monitor_by_user
    match 'course/progress_monitor_by_user' => 'courses#progress_monitor_by_user', :as => 'progress_monitor_by_user'

  #for omniauth
    resources :authentications

    match '/auth/:provider/callback' => 'authentications#create'

  #Devise
    devise_for :users, :controller => { :registrations => 'registrations'}
    #root for method after_sign_out
    root :to => "courses#index"

  #fb_graph
    #send_data_to_3D
    match 'facebook_activity/send_data_to_3D' => 'facebook_activity#send_data_to_3D', :as => 'send_data_to_3D'

    resources :facebook_activity
    
    #post_wall
    post '/facebook_activity/post_wall' => 'facebook_activity#post_wall', :as => 'post_wall'
    #action_wall
    post 'facebook_activity/action_wall' => 'facebook_activity#action_wall', :as => 'action_wall'
    #get_fb_friends
    match 'facebook_activity/get_fb_friends' => 'facebook_activity#get_fb_friends', :as => 'get_fb_friends'
    #send_data_to_3D
    #match 'facebook_activity/send_data_to_3D' => 'facebook_activity#send_data_to_3D', :as => 'send_data_to_3D'
    

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
