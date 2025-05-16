import React, { useEffect, useState } from "react";

function App() {
  const [message, setMessage] = useState("Cargando...");
  const [nombre, setNombre] = useState("");
  const [respuesta, setRespuesta] = useState("");

  useEffect(() => {
ñ    fetch("http://179.5.119.85/api/message")
      .then((res) => res.json())
      .then((data) => setMessage(data.message))
      .catch(() => setMessage("Error al obtener mensaje"));
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setRespuesta("Enviando...");
    try {
      const res = await fetch("http://179.5.119.85/api/message", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nombre }),
      });
      const data = await res.json();
      setRespuesta(data.message);
    } catch {
      setRespuesta("Error al enviar mensaje");
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-100 to-purple-100 flex flex-col items-center justify-center p-4">
      <div className="bg-white/90 backdrop-blur-sm shadow-xl rounded-3xl p-10 max-w-md w-full text-center border border-indigo-100">
        <h1 className="text-4xl font-extrabold mb-6 bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
          Proyecto Fullstack
        </h1>
        <p className="text-gray-700 text-lg font-medium">{message}</p>
        <form className="mt-8 flex flex-col gap-4" onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Ingresa tu nombre"
            value={nombre}
            onChange={(e) => setNombre(e.target.value)}
            className="border border-indigo-200 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all shadow-sm hover:shadow-md"
          />
          <button
            type="submit"
            className="px-6 py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl hover:from-indigo-600 hover:to-purple-600 transition-all duration-300 font-semibold shadow-md hover:shadow-lg transform hover:-translate-y-0.5"
          >
            Enviar nombre
          </button>
        </form>
        {respuesta && (
          <p className="mt-6 text-emerald-600 font-semibold bg-emerald-50 py-3 px-4 rounded-lg border border-emerald-100">
            {respuesta}
          </p>
        )}
        <button
          className="mt-8 px-6 py-3 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-xl hover:from-indigo-600 hover:to-purple-600 transition-all duration-300 font-semibold shadow-md hover:shadow-lg transform hover:-translate-y-0.5 w-full"
          onClick={() => window.location.reload()}
        >
          Recargar mensaje
        </button>
      </div>
    </div>
  );
}

export default App;
