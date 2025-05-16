from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Permitir solicitudes CORS desde React

@app.route('/api/message')
def get_message():
    return jsonify({ 'message': '¡Hola desde Flask!' })

@app.route('/api/message', methods=['POST'])
def post_message():
    data = request.get_json()
    nombre = data.get('nombre', 'invitado')
    return jsonify({'message': f'¡Hola, {nombre}! Recibimos tu mensaje.'})

