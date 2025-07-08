#!/bin/bash
LANG="$1"
url=$(zenity --entry --title="${LANG^} HTTP GET" --text="Enter URL:")

case "$LANG" in
  python)
    snippet="import requests\nresponse = requests.get('${url}')\nprint(response.text)"
    ;;
  java)
    snippet="HttpClient client = HttpClient.newHttpClient();\nHttpRequest request = HttpRequest.newBuilder().uri(URI.create(\"${url}\")).build();\nHttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());\nSystem.out.println(response.body());"
    ;;
  kotlin)
    snippet="val response = khttp.get(\"${url}\")\nprintln(response.text)"
    ;;
  typescript)
    snippet="fetch('${url}').then(res => res.text()).then(console.log);"
    ;;
  go)
    snippet="resp, err := http.Get(\"${url}\")\nif err != nil {\n    log.Fatal(err)\n}\ndefer resp.Body.Close()\nbody, _ := io.ReadAll(resp.Body)\nfmt.Println(string(body))"
    ;;
  *)
    zenity --error --text="Unsupported language."; exit 1 ;;
esac

echo -e "$snippet"
