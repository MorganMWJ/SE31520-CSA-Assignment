# User.delete_all
# UserDetail.delete_all
# Feed.delete_all
# Post.delete_all

User.transaction do

  1..40.times do |i|
    user = User.create(surname: "Surname#{i}",
                       firstname: "Firstname#{i}",
                       email: "cwl#{i}@aber.ac.uk",
                       phone: '01970 622422',
                       grad_year: 1985)
    UserDetail.create!(login: "cwl#{i}",
                       password: 'secret',
                       user: user)
  end

  # Create one special admin user
  aduser = User.create!(surname: 'Loftus',
                      firstname: 'Chris',
                      email: 'cwl@aber.ac.uk',
                      phone: '01970 622422',
                      grad_year: 1985)
  UserDetail.create!(login: 'admin',
                     password: 'taliesin',
                     user: aduser)

  # Create some dummy feeds
  Feed.create!(name: 'twitter')
  Feed.create!(name: 'facebook')
  Feed.create!(name: 'email')
  Feed.create!(name: 'RSS')
  Feed.create!(name: 'atom')
  Feed.create!(name: 'notification')

  my_post = Post.create!(id: 1, title: 'Sunny Days', body: 'I love sunny days, they make me happy.', anonymous: false, user: aduser, thread: nil)
  puts my_post.inspect
  # Post.create!([
  #   {id: 1, title: 'Sunny Days', body: 'I love sunny days, they make me happy.', anonymous: false, user: aduser, post: nil},
  #   {id: 2, title: 'Surfing', body: 'Surfing is super awesome!', anonymous: false, user: aduser, post: nil},
  #   {id: 3, title: 'Drinking Beer', body: 'Beer is a bad drink. It makes you hungover!', anonymous: false, user: aduser, post: nil},
  #   {id: 4, title: 'Ruby On Rails', body: 'Is an important part of my learning.', anonymous: false, user: aduser, post: nil},
  #   {id: 5, title: 'Computing Protocols', body: 'HTTP, FTP, SMTP, ICMP, TCP, UDP, IP, ARP. Are all cool to learn.', anonymous: false, user: aduser, post: nil},
  #   {id: 6, title: 'Genetic Algorithms', body: 'Genetic Algorithms are a very interesting area of computer science.', anonymous: false, user: aduser, post: nil}
  #   ])

end
