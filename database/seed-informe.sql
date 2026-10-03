DO $seed$
DECLARE
    v_article_id integer;
    v_asset_id integer;
    v_parent_asset_id integer;
    v_asset_right bigint;
    v_parent_level integer;
    v_category_id integer;
    v_author_id integer;
    v_title text := 'Informe Técnico - Arquitectura y Análisis del Modelo OSI';
    v_alias text := 'informe-tecnico-arquitectura-modelo-osi';
    v_body text := $html$
<h1>Informe Técnico - Arquitectura y Análisis del Modelo OSI</h1>
<h2>Sección 1: Topología y Flujo de Información</h2>
<h3>Diagrama de Arquitectura</h3>
<p>El ecosistema cuenta con 5 contenedores docker comunicándose mediante dos redes virtuales aisladas.</p>
<ul>
  <li><strong>Nginx</strong> actúa como <em>Edge Router</em> (puerto 80) y expone Joomla (raíz <code>/</code>), Jupyter (<code>/jupyter</code>) y Grafana (<code>/grafana</code>).</li>
  <li><strong>Jupyter</strong> se conecta al backend para las consultas a la base de datos.</li>
  <li><strong>Grafana</strong> consulta la actividad directamente en PostgreSQL para recolectar métricas de la base de datos que aloja Joomla.</li>
</ul>
<h3>Mecanismo de Recolección de Logs / Métricas</h3>
<p>La recolección de métricas se realiza conectando directamente <strong>Grafana</strong> a la base de datos <strong>PostgreSQL</strong>. Se configuró un datasource automatizado mediante archivos YAML (Provisioning). Para no requerir de pasos manuales, los dashboards ejecutan consultas a las vistas del sistema <code>pg_stat_database</code> para recolectar, de forma desatendida y persistente, datos de transacciones, uso y volumen de registros.</p>
<h2>Sección 2: Análisis Detallado del Modelo OSI</h2>
<h3>Capa 7 (Aplicación)</h3>
<ul>
  <li><strong>Cabeceras HTTP de Nginx:</strong> Nginx inyecta cabeceras de proxy inverso (Host, X-Forwarded-For, X-Forwarded-Proto) permitiendo que los servicios backend conozcan la IP real del cliente que inició la petición.</li>
  <li><strong>HTTP Upgrade:</strong> En Nginx se emplean las directivas <code>proxy_set_header Upgrade $http_upgrade;</code> y <code>Connection "upgrade";</code>. Estas interceptan el handshake HTTP tradicional y permiten la transición a WebSockets bidireccionales, esenciales para el kernel y la consola en Jupyter.</li>
  <li><strong>Protocolos Cliente/Servidor:</strong> PostgreSQL utiliza su propio protocolo de aplicación TCP. Joomla, al generar y procesar peticiones, se comunica contra la base de datos como cliente.</li>
</ul>
<h3>Capa 4 (Transporte)</h3>
<ul>
  <li><strong>Puertos TCP:</strong> Se exponen únicamente puertos internos entre contenedores (5432 para Postgres, 3000 Grafana, 8888 Jupyter). Únicamente Nginx publica el 80 hacia el exterior.</li>
  <li><strong>Conexiones Concurrentes y Persistentes:</strong> PostgreSQL y los motores WSGI (Jupyter) manejan multiplexación de conexiones. Utilizan el mecanismo <em>keep-alive</em> para mantener los sockets TCP abiertos y realizar <em>connection pooling</em>, optimizando la transferencia de consultas de Joomla y los dashboards de Grafana hacia la DB sin reabrir conexiones de capa 4.</li>
</ul>
<h3>Capa 3 (Red)</h3>
<ul>
  <li><strong>Direccionamiento IP y Aislamiento:</strong> El entorno define dos puentes de red (<code>frontend_net</code> y <code>backend_net</code>). El contenedor <code>database</code> pertenece <strong>solo</strong> a <code>backend_net</code> y dicha red se configuró con <code>internal: true</code>. Por ello, la base de datos tiene total aislamiento lógico: ni interactúa con la red exterior ni es alcanzable a través del host.</li>
  <li><strong>Resolución DNS Embebida (127.0.0.11):</strong> Docker proporciona un servidor DNS embebido. Este intercepta resoluciones de nombre (<code>database</code>, <code>joomla</code>) a sus correspondientes IPs virtuales, permitiendo un direccionamiento agnóstico.</li>
  <li><strong>Reglas de Reenvío (NAT):</strong> El kernel del host Linux/Windows maneja automáticamente reglas <code>iptables</code>/NAT para enrutar el tráfico entrante al puerto 80 del Nginx.</li>
</ul>
<h3>Capa 2 (Enlace de Datos)</h3>
<ul>
  <li><strong>Interfaces Virtuales (veth*):</strong> Cada contenedor se engancha a su respectivo bridge con pares <code>veth</code>. Cuando Joomla habla con la base de datos, las tramas Ethernet viajan del veth de Joomla al switch virtual (br-*) correspondiente a <code>backend_net</code>.</li>
  <li><strong>Resolución ARP Interna:</strong> Los contenedores en el mismo bridge resuelven las MAC addresses de sus destinos por medio de ARP normal encapsulado en el switch virtual de Docker.</li>
</ul>
<h2>Sección 3: Guía de Verificación y Demostración</h2>
<p>Para validar el ecosistema:</p>
<ol>
  <li>Levantar con <code>docker compose up -d</code> y esperar aproximadamente 30-40 segundos para que PostgreSQL asuma el estado "healthy" y todos los servicios dependientes arranquen.</li>
  <li>Navegar a <code>http://localhost/</code> (Joomla) y generar navegación básica por el sitio.</li>
  <li>Navegar a <code>http://localhost/grafana/</code> (si pide inicio de sesión, usa admin/admin o sáltalo). Entrar a Dashboards -&gt; "Actividad de Base de Datos y Joomla". Verificar las gráficas de series temporales que muestran el crecimiento de transacciones y uso de PostgreSQL.</li>
  <li>Navegar a <code>http://localhost/jupyter/</code>. Entrará de forma automática sin pedir Token. Entrar a <code>analisis_datos.ipynb</code> y ejecutar (Shift+Enter) todas las celdas de Python. Verificar que importe las librerías preinstaladas e imprima satisfactoriamente la tabla que extrae del PostgreSQL.</li>
</ol>
<h2>Sección 4: Estructura de Archivos del Proyecto</h2>
<p>A continuación se muestra la distribución final ("tree") de los archivos del parcial:</p>
<pre><code>.
|-- GUIA_PARCIAL.md
|-- INFORME.md
|-- README.md
|-- docker-compose.yml
|-- escudo.svg
|-- grafana
|   `-- provisioning
|       |-- dashboards
|       |   |-- dashboard.yml
|       |   `-- joomla_logs.json
|       `-- datasources
|           `-- datasource.yml
|-- jupyter
|   |-- Dockerfile
|   `-- notebooks
|       `-- analisis_datos.ipynb
|-- nginx
|   `-- default.conf
`-- setup-joomla.sh</code></pre>
<h2>Sección 5: Estrategias de Automatización (Zero-Touch)</h2>
<p>Para cumplir con el requerimiento de que el proyecto se ejecute sin intervención manual en cualquier equipo, se implementaron las siguientes automatizaciones:</p>
<ol>
  <li><strong>Instalación Desatendida de Joomla:</strong> A través de variables de entorno (<code>JOOMLA_SITE_NAME</code>, <code>JOOMLA_ADMIN_USER</code>, etc.) en el <code>docker-compose.yml</code>, la imagen oficial de Joomla realiza la instalación completa de la base de datos sin mostrar el asistente web.</li>
  <li><strong>Sidecar de Inyección (setup-joomla.sh):</strong> Un contenedor efímero basado en Alpine/Postgres espera a que Joomla genere sus tablas y luego inyecta directamente mediante SQL un módulo personalizado en la página principal. Este módulo incluye el escudo de la Universidad (descargado de Wikimedia Commons) y botones de acceso rápido a Jupyter y Grafana.</li>
  <li><strong>Resolución DNS Dinámica en Nginx:</strong> Nginx falla críticamente si en el momento de arrancar no encuentra el host al que apunta un <code>proxy_pass</code>. Se implementó un <code>resolver 127.0.0.11 valid=10s;</code> y variables dinámicas (<code>set $joomla_up http://joomla:80;</code>) para tolerar que los contenedores backend tarden más en encender.</li>
  <li><strong>Jupyter con Dependencias Preinstaladas:</strong> Se creó un <code>Dockerfile</code> propio para Jupyter que preinstala <code>psycopg2-binary</code>, <code>pandas</code>, <code>sqlalchemy</code> y <code>matplotlib</code>. Esto elimina la necesidad de ejecutar comandos <code>!pip install</code> en los cuadernos y evita fallos si el host no tiene conexión a internet rápida al momento de instalar. Además, se deshabilitó el token de autenticación para facilitar el acceso instantáneo.</li>
</ol>
$html$;
BEGIN
    IF EXISTS (SELECT 1 FROM public.orb9u_content WHERE alias = v_alias) THEN
        UPDATE public.orb9u_content
        SET introtext = v_body
        WHERE alias = v_alias;
        RETURN;
    END IF;

    SELECT id INTO v_category_id
    FROM public.orb9u_categories
    WHERE extension = 'com_content' AND alias = 'uncategorised'
    ORDER BY id
    LIMIT 1;

    SELECT id INTO v_author_id
    FROM public.orb9u_users
    ORDER BY id
    LIMIT 1;

    SELECT a.id, a.rgt, a.level
    INTO v_parent_asset_id, v_asset_right, v_parent_level
    FROM public.orb9u_categories AS c
    JOIN public.orb9u_assets AS a ON a.id = c.asset_id
    WHERE c.id = v_category_id;

    IF v_category_id IS NULL OR v_author_id IS NULL OR v_parent_asset_id IS NULL THEN
        RAISE EXCEPTION 'Joomla article category, author, or category asset is missing';
    END IF;

    INSERT INTO public.orb9u_content (
        asset_id, title, alias, introtext, fulltext, state, catid,
        created, created_by, created_by_alias, modified, modified_by,
        checked_out, checked_out_time, publish_up, publish_down,
        images, urls, attribs, version, ordering, metakey, metadesc,
        access, hits, metadata, featured, language, note
    ) VALUES (
        0,
        v_title,
        v_alias,
        v_body,
        '',
        1,
        v_category_id,
        CURRENT_TIMESTAMP,
        v_author_id,
        '',
        CURRENT_TIMESTAMP,
        v_author_id,
        NULL,
        NULL,
        NULL,
        NULL,
        '{}',
        '{}',
        '{}',
        1,
        0,
        NULL,
        'Análisis de arquitectura multi-contenedor y modelo OSI.',
        1,
        0,
        '{}',
        0,
        '*',
        ''
    ) RETURNING id INTO v_article_id;

    UPDATE public.orb9u_assets
    SET rgt = rgt + 2
    WHERE rgt >= v_asset_right;

    UPDATE public.orb9u_assets
    SET lft = lft + 2
    WHERE lft >= v_asset_right;

    INSERT INTO public.orb9u_assets (parent_id, lft, rgt, level, name, title, rules)
    VALUES (
        v_parent_asset_id,
        v_asset_right,
        v_asset_right + 1,
        v_parent_level + 1,
        'com_content.article.' || v_article_id,
        v_title,
        '{}'
    ) RETURNING id INTO v_asset_id;

    UPDATE public.orb9u_content
    SET asset_id = v_asset_id
    WHERE id = v_article_id;
END;
$seed$;