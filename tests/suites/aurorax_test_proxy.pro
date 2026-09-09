; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------
;
; Tests for the proxy configuration helpers.
;
; These write to process environment variables, so the suite saves whatever
; was there on the way in and puts it back on the way out. Otherwise running
; the tests would quietly clobber a developer's real proxy settings for the
; rest of the IDL session.

pro aurorax_test_proxy
  compile_opt idl2

  ; save the incoming environment
  saved_hostname = getenv('AURORAX_PROXY_HOSTNAME')
  saved_port = getenv('AURORAX_PROXY_PORT')
  saved_username = getenv('AURORAX_PROXY_USERNAME')
  saved_password = getenv('AURORAX_PROXY_PASSWORD')

  ; -----------------------------------------------------------
  atest_suite, 'proxy -- set and get round trip'
  ; -----------------------------------------------------------
  aurorax_set_proxy, 'proxy.example.com', 8080

  p = aurorax_get_proxy()
  atest_not_null, p, 'the proxy settings come back'
  atest_has_tag, p, 'hostname', 'settings include a hostname'
  atest_has_tag, p, 'port', 'settings include a port'
  atest_has_tag, p, 'username', 'settings include a username'
  atest_has_tag, p, 'password', 'settings include a password'

  atest_equal, p.hostname, 'proxy.example.com', 'the hostname round trips'
  atest_equal, p.port, '8080', 'the port round trips'

  ; the port comes back as a string, not a number -- it is stored in an
  ; environment variable and the call sites re-parse it with fix()
  atest_true, isa(p.port, /string), 'the port is returned as a string'

  atest_equal, p.username, '', 'an unset username comes back as an empty string'
  atest_equal, p.password, '', 'an unset password comes back as an empty string'

  ; -----------------------------------------------------------
  atest_suite, 'proxy -- with credentials'
  ; -----------------------------------------------------------
  aurorax_set_proxy, 'proxy.example.com', 3128, username = 'someone', password = 'secret'

  p = aurorax_get_proxy()
  atest_equal, p.hostname, 'proxy.example.com', 'the hostname round trips with credentials set'
  atest_equal, p.port, '3128', 'the port round trips with credentials set'
  atest_equal, p.username, 'someone', 'the username round trips'
  atest_equal, p.password, 'secret', 'the password round trips'

  ; -----------------------------------------------------------
  atest_suite, 'proxy -- clear'
  ; -----------------------------------------------------------
  aurorax_clear_proxy

  p = aurorax_get_proxy()
  atest_equal, p.hostname, '', 'clearing empties the hostname'
  atest_equal, p.port, '', 'clearing empties the port'
  atest_equal, p.username, '', 'clearing empties the username'
  atest_equal, p.password, '', 'clearing empties the password'

  ; the request routines decide whether to apply a proxy by testing
  ; hostname and port against '', so cleared really does mean disabled
  atest_true, (p.hostname eq '') and (p.port eq ''), $
    'a cleared proxy reads as disabled to the request routines'

  ; -----------------------------------------------------------
  atest_suite, 'proxy -- overwriting'
  ; -----------------------------------------------------------
  aurorax_set_proxy, 'first.example.com', 1111, username = 'user1', password = 'pass1'
  aurorax_set_proxy, 'second.example.com', 2222

  p = aurorax_get_proxy()
  atest_equal, p.hostname, 'second.example.com', 'a second call replaces the hostname'
  atest_equal, p.port, '2222', 'a second call replaces the port'
  atest_equal, p.username, '', 'a second call without credentials clears the previous username'
  atest_equal, p.password, '', 'a second call without credentials clears the previous password'

  ; -----------------------------------------------------------
  ; restore whatever the developer had configured before the suite ran
  ; -----------------------------------------------------------
  setenv, 'AURORAX_PROXY_HOSTNAME=' + saved_hostname
  setenv, 'AURORAX_PROXY_PORT=' + saved_port
  setenv, 'AURORAX_PROXY_USERNAME=' + saved_username
  setenv, 'AURORAX_PROXY_PASSWORD=' + saved_password

  p = aurorax_get_proxy()
  atest_equal, p.hostname, saved_hostname, 'the incoming proxy configuration was restored'
end
