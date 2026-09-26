---

### 2. Archivo `INFORME.md`

Crea el archivo **`INFORME.md`** en la raíz del proyecto (`parcial/`)[cite: 1]. Este archivo satisface todos los puntos teóricos del Modelo OSI exigidos por el docente[cite: 1]:

```markdown
# Informe Técnico: Arquitectura Multi-Contenedor y Análisis del Modelo OSI

**Asignatura:** Comunicaciones  
**Carrera:** Ingeniería Mecatrónica  
**Universidad Militar Nueva Granada**  

---

## Sección 1: Topología y Flujo de Información

### Diagrama de Arquitectura
La solución consta de 5 contenedores orquestados sobre dos redes tipo bridge aisladas (`frontend_net` y `backend_net`):

```text
               [ Navegador del Cliente ]
                           |
                     HTTP (Puerto 80)
                           v
                 +-------------------+
                 |       nginx       |
                 |  (Reverse Proxy)  |
                 +---------+---------+
                           |
       +-------------------+-------------------+
       | (HTTP)            | (WebSockets/HTTP) | (HTTP)
       v                   v                   v
+--------------+    +--------------+    +--------------+
|    joomla    |    |   jupyter    |    |   grafana    |
|    (CMS)     |    |    (Lab)     |    |  (Paneles)   |
+-------+------+    +--------------+    +-------+------+
        |                                       |
        | TCP: 5432                             | Consultas SQL
        +------------------+--------------------+
                           |
                           v
                 +-------------------+
                 |     database      |
                 |   (PostgreSQL)    |
                 +-------------------+
