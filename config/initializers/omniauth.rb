Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, '373518166042529', '24a9e3b9694d67b420953e9c514c8de3', { :scope => 'email'}
  #provider :twitter, 'DiBlIui2JWbnO06Jzwuaw', 'RYI8TWLquo99ltKZAmc2s1RPwJteXIJPR9ei45b7E'
end
