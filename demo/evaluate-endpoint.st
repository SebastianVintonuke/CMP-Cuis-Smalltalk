"Endpoint de desarrollo para mirar y actuar en la imagen desde afuera.

No es parte del paquete MCPServer: es la puerta que usamos *antes* de que exista un
servidor MCP, y la que usa el panel (demo/panel-mcp.py, parametro --cuis) para levantar
y apagar el servidor. Se pega en un Workspace de la imagen y queda escuchando en
localhost.

Ojo: vive en la imagen que esta corriendo. Si apagas y volves a levantar la imagen,
hay que pegarlo otra vez (o guardar la imagen con el servidor andando).

Para apagarlo: (Smalltalk at: #CuisDevEndpoint) destroy"

| server |
server := WebServer new listenOn: 8765 interface: #(127 0 0 1).
server addService: '/evaluate' action: [ :req |
	| answer |
	answer := [ (Compiler evaluate: req content) printString ]
		on: Error
		do: [ :error | 'ERROR ', error class name, ': ', error messageText ].
	req send200Response: answer ].
Smalltalk at: #CuisDevEndpoint put: server.
server
