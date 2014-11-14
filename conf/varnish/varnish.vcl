include "/usr/local/varnish/etc/varnish/backends.vcl";

acl local {
        "localhost";
        "127.0.0.1";
        "192.168.1.0"/24;
}

sub vcl_recv {
        if (req.request == "PURGE") {
                  if (!client.ip ~ local) {
                           error 405 "Not Allowed.";
                           return (lookup);
                  }
        }

        if (req.http.host == abc) {
                  set req.backend = CACHE_LB;
        }

        if (req.url ~ "/feed") {
                  return (pass);
        }

        if (req.restarts == 0) {
                  if (req.http.x-forwarded-for) {
                           set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " +client.ip;
                  } else {
                           set req.http.X-Forwarded-For = client.ip;
                  }
        }

        if (req.request != "GET" &&
                  req.request != "HEAD" &&
                  req.request != "PUT" &&
                  req.request != "POST" &&
                  req.request != "TRACE" &&
                  req.request != "OPTIONS" &&
                  req.request != "DELETE") {
                  return (pipe);
        }

        if (req.request != "GET" && req.request != "HEAD") {
                  return (pass);
        }

        if (req.http.Authorization || req.request == "POST") {
                  return (pass);
        }

        if ((req.request == "GET" || req.request == "HEAD") && req.url ~ "\.(png|gif|jpeg|swf|css|js|jpg)$") {
                  return (lookup);
        }

        if (req.request == "GET" && req.url ~ "\.(php)($|\?)"){
                  return (pass);
        }

        if (req.http.Accept-Encoding) {
                  if (req.url ~ "\.(jpg|jpge|png|gif|mp3|mp4|ogg|flv)$") {
                           remove req.http.Accept-Encoding;
                  } elseif (req.http.Accept-Encoding ~ "gzip") {
                           set req.http.Accept-Encoding = "gzip";
                  } elseif (req.http.Accept-Encoding ~ "deflate") {
                           set req.http.Accept-Encoding = "deflate";
                  } else {
                           remove req.http.Accept-Encoding;
                  }
        }

        if (req.http.Authorization || req.http.Cookie) {
                  return (pass);
        }

        set req.grace = 30s;

        return (lookup);
}

sub vcl_pipe {
        return (pipe);
}

sub vcl_pass {
        return (pass);
}

sub vcl_hash {
        hash_data(req.url);

        if (req.http.host == abc) {
                  hash_data(req.http.host);
        } else {
                  hash_data(server.ip);
        }

        #if (req.http.Accept-Encoding ~ "gzip") {
        #       hash_data("gzip");
        #} elseif (req.http.Accept-Encoding ~ "deflate") {
        #       hash_data("deflate");
        #}

        if (req.http.Accept-Encoding) {
                  hash_data(req.http.Accept-Encoding);
        }

        return (hash);
}

sub vcl_hit {
        if (req.request == "PURGE") {
                  purge;
                  error 200 "Purged.";
        }

        return (deliver);
}

sub vcl_miss {
        if (req.request == "PURGE") {
                  purge;
                  error 200 "Purged.";
        }

        return (fetch);
}

sub vcl_fetch {
        set beresp.grace = 20m;

        if (req.request == "POST" || req.http.Authorization) {
                  return (hit_for_pass);
        }

        if (beresp.http.Pragma ~ "no-cache" ||
                  beresp.http.Cache-Control ~ "no-cache" ||
                  beresp.http.Cache-Control ~ "private") {
                  return (hit_for_pass);
        }

        if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary =="*") {
                  set beresp.ttl = 120s;
                  return (hit_for_pass);
        }

        if (req.request == "GET" && req.url ~ "\.(txt|shtml|htm|html|js|css|gif|jpg|jpeg|png|bmp|ico|swf|flv)$"){
                  set beresp.ttl = 15m;
        } else {
                  set beresp.ttl = 10m;
        }

        if (beresp.status != 200) {
                  return (hit_for_pass);
        }

        return (deliver);
}

sub vcl_deliver {
        set resp.http.x-hits = obj.hits;

        if (obj.hits > 0) {
                  set resp.http.X-Cache = "HIT from proxy cache";
        } else {
                  set resp.http.X-Cache = "MISS from proxy cache";
        }
        return (deliver);
}

sub vcl_error {
        set obj.http.Content-Type = "text/html; charset=utf-8";
        set obj.http.Retry-After = "5";

        synthetic{"
                  <?xml version="1.0" encoding="utf-8" ?>
                  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN""http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                  <html>
                  <head>
                  <title>"} + obj.status + " " + obj.response + {"</title>
                  </head>
                  <body>
                  <h1>Error"} + obj.status + " " + obj.response + {"</h1>
                  <p>"} + obj.response + {"</p>
                  <h3>Guru Meditation:</h3>
                  <p>XID:"} + req.xid + {"</p>
                  <hr>
                  <p>Varnish Cache Server</p>
                  </body>
                  </html>
        "};

        return (deliver);
}

sub vcl_init {
        return (ok);
}

sub vcl_fini {
        return (ok);
}
