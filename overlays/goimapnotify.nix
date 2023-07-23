final: prev:

{
  goimapnotify = prev.goimapnotify.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace client.go \
        --replace 'client.Dial(fmt.Sprintf("%s:%d", conf.Host, conf.Port))' \
          'client.Dial(fmt.Sprintf("%s:%d", conf.Host, conf.Port))
                  err = c.StartTLS(&tls.Config{
                          ServerName:         conf.Host,
                          InsecureSkipVerify: !conf.TLSOptions.RejectUnauthorized,
                  })'
      substituteInPlace client.go \
        --replace 'client.Dial(conf.Host + fmt.Sprintf(":%d", conf.Port))' \
          'client.Dial(conf.Host + fmt.Sprintf(":%d", conf.Port))
                  err = c.StartTLS(&tls.Config{
                          ServerName:         conf.Host,
                          InsecureSkipVerify: !conf.TLSOptions.RejectUnauthorized,
                  })'
    '';
  });
}
