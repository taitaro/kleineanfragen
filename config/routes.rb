require 'resque/server'

Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  resque_web_constraint = ->(_, request) { ['::1', '127.0.0.1'].include?(request.remote_ip) || ENV['RESQUE_SERVER_OPEN'].present? }
  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/.resque'
  end

  get 'search' => 'paper#search', as: :search
  get 'search/autocomplete' => 'paper#autocomplete'

  get 'recent' => 'paper#recent'

  get 'info/daten'
  get 'info/kontakt'
  get 'info/mitmachen'

  get 'review' => 'review#index'
  get 'review/papers'
  get 'review/ministries'
  get 'review/today'

  get 'abo', to: redirect('/')
  post 'abo' => 'subscription#subscribe', as: :subscription_create

  get 'm/:subscription/confirm/:confirmation_token' => 'opt_in#confirm', as: :opt_in_confirm
  get 'm/:subscription/report/:confirmation_token' => 'opt_in#report', as: :opt_in_report
  get 'm/:subscription/unsubscribe' => 'subscription#unsubscribe', as: :unsubscribe

  # really short paper url used for debugging jobs
  get 'p:paper' => 'paper#redirect_by_id', constraints: { paper: /[0-9]+/ }

  get ':body/abo' => 'body#subscribe', as: :body_subscribe
  get ':body/behoerde/:ministry' => 'ministry#show', as: :ministry

  get ':body/:legislative_term/:paper/viewer' => 'paper#viewer', as: :paper_pdf_viewer, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term/:paper' => 'paper#show', as: :paper, constraints: { legislative_term: /[0-9]+/ }
  get ':body/:legislative_term' => 'legislative_term#show', as: :legislative_term, constraints: { legislative_term: /[0-9]+/ }
  get ':body' => 'body#show', as: :body, body: /[^0-9\/]+/, format: false

  root 'site#index'
end