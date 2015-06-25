var http = require("http");
var server = http.createServer(function(request, response) {
  response.writeHead(200, {"Content-Type": "text/html"});
  response.write("<!DOCTYPE 'html'>");
  response.write("<html>");
  response.write("<head>");
  response.write("<title>Hello World Page</title>");
  response.write("</head>");
  response.write("<body><div>");response.write("Hello World!");response.write("This works");response.write("</div></body>");
  response.write("</html>");
  response.end();
});
 
server.listen(3006);
console.log("Server is listening");