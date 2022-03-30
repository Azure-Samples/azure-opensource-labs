# DOCKER

[back](README.md)

If you have Docker installed locally, you have three options to build and run the Flask application inside a container.

> __IMPORTANT__: This section is **for illustrative purposes only** and you **do not** need to run these commands. 

Clone the Visual Studio Code Flask tutorial:

```bash
git clone https://github.com/Microsoft/python-sample-vscode-flask-tutorial
cd python-sample-vscode-flask-tutorial/
```

Run the application from inside of a Docker container: 

```bash
docker run --rm -v ${PWD}:/pwd/ -w /pwd/ -p 8080:5000 -it python bash
pip install -r requirements.txt
export FLASK_APP=startup.py
flask run --host=0.0.0.0
# open http://localhost:8080
```

Build a *development* container from a `Dockerfile` ([dev.Dockerfile](dev.Dockerfile)).

```bash
docker build -f dev.Dockerfile -t test python-sample-vscode-flask-tutorial/
docker run --rm -p 8080:5000 -it test
# open http://localhost:8080
```

Build a *production* container from a `Dockerfile` ([prod.Dockerfile](prod.Dockerfile)).
```bash
docker build -f prod.Dockerfile -t prod python-sample-vscode-flask-tutorial/
docker run --rm -p 8080:5000 -it prod
# open http://localhost:8080
```
