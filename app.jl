    

using Bonito
# The app you want to serve
#  Note: you can also add more pages with `route!(server, ...)` as explained aboce
my_app = App(DOM.div("hello world"))
port = parse(Int, ENV["PORT"])
# needs to match `heroku create - a example-app`,
# which we can ensure by using the env variable
# which is only available in review app, so one needs to fill this in manually for now
#
url="https://bie-demo-test.onrender.com"
@info port
wait(Bonito.Server(my_app, "0.0.0.0", port, proxy_url=url))