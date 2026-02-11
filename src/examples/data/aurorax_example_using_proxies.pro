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

pro aurorax_example_using_proxies
  ; ------------------------
  ; Using IDL-AuroraX with a proxy connection
  ; ------------------------
  ;
  ; Some networks require you to utilize a proxy connection to access the internet. To
  ; help facilitate usage of IDL-AuroraX for this situation, we have a few helper procedures
  ; and functions. Using these allows for configuring a proxy connection that the library can
  ; lean on for API requests and data download.
  ;
  ; WARNING: IDL only supports the use of a HTTP/HTTPS proxy. SOCKS proxies are not supported.
  ; If you try the proxy configuration and perform a function that talks to our API or
  ; downloads data and you receive an error saying something like 'Proxy CONNECT aborted',
  ; this likely means the proxy you are trying to use is SOCKS and not HTTP/HTTPS.
  ;
  ; The below examples assume that you are already connected to a proxy that can be interacted
  ; with by using a hostname of 'localhost' and port 9000. Adjust this example as needed.

  ; Initialize the proxy connection details with IDL-AuroraX. This step must be performed
  ; each time IDL is started. It will set environment variables.
  aurorax_set_proxy, 'localhost', 9000

  ; If your proxy requires a username and password, this is how you'd initialize it.
  ;
  ; aurorax_set_proxy, 'localhost', 9000, username='testing', password='something'

  ; Now, we can proceed with any usage of the library as you would normally. The proxy
  ; connection details will be automatically checked and used if set.
  ;
  ; Let's do a simple test by listing datasets
  datasets = aurorax_list_datasets()
  print, 'Found ' + strcompress(fix(n_elements(datasets)), /remove_all) + ' datasets'
  help, datasets[0]
  print, ''

  ; If you want to know if the proxy settings are currently set, you can use a helper
  ; method to check.
  print, 'Getting current proxy settings'
  help, aurorax_get_proxy()
  print, ''

  ; And lastly, we can also clear our proxy connection settings if you ever need to.
  print, 'Clearing proxy settings'
  aurorax_clear_proxy
  help, aurorax_get_proxy()
end
