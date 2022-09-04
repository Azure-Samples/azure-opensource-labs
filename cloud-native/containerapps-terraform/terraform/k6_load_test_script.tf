resource "local_file" "helloworld" {
  filename = "./k6_scripts.js"
  content = templatefile("./k6_scripts.tmpl",
    {
      INGRESS_FQDN = format("%s%s", "https://", jsondecode(azapi_resource.helloworld.output).properties.configuration.ingress.fqdn)
    }
  )
}