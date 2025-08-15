const firebaseConfig = {
    apiKey: "AIzaSyA36lkZXwENIMlw_irQLA0CjcVuVfZRTH8",
    authDomain: "fotohora-369.firebaseapp.com",
    databaseURL: "https://fotohora-369-default-rtdb.firebaseio.com",
    projectId: "fotohora-369",
    storageBucket: "fotohora-369.firebasestorage.app"
};

firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.database();

auth.onAuthStateChanged(user => {
    if (!user) {
        window.location.href = 'auth.html';
    } else {
        initMap();
    }
});

function initMap() {
    const map = L.map('map').setView([4.7110, -74.0721], 13);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    const deviceLayers = {};
    const deviceMarkers = {};
    const deviceColors = {};
    
    db.ref('dispositivos').on('value', snapshot => {
        const devices = snapshot.val();
        const deviceList = document.getElementById('device-list');
        deviceList.innerHTML = '';
        
        for (const mac in devices) {
            if (!devices.hasOwnProperty(mac)) continue;
            
            const device = devices[mac];
            deviceColors[mac] = device.color || getRandomColor();
            
            const deviceItem = document.createElement('div');
            deviceItem.className = 'device-item';
            deviceItem.innerHTML = `
                <input type="checkbox" id="${mac}" class="device-checkbox">
                <label for="${mac}" style="color:${deviceColors[mac]}">
                    ${device.nombre || mac}
                </label>
                <input type="color" class="color-picker" value="${deviceColors[mac]}" 
                       data-mac="${mac}">
            `;
            deviceList.appendChild(deviceItem);
            
            document.getElementById(mac).addEventListener('change', e => {
                if (e.target.checked) loadDevicePath(mac);
                else clearDevicePath(mac);
            });
            
            deviceItem.querySelector('.color-picker').addEventListener('change', e => {
                const newColor = e.target.value;
                deviceColors[mac] = newColor;
                db.ref(`dispositivos/${mac}/color`).set(newColor);
                if (deviceLayers[mac]) deviceLayers[mac].setStyle({ color: newColor });
            });

            // Actualizar marcador de última ubicación
            if (device.ultima_ubicacion) {
                const lat = device.ultima_ubicacion.lat;
                const lng = device.ultima_ubicacion.lng;
                
                if (deviceMarkers[mac]) {
                    deviceMarkers[mac].setLatLng([lat, lng]);
                } else {
                    deviceMarkers[mac] = L.marker([lat, lng], {
                        title: device.nombre || mac
                    }).addTo(map);
                }
            }
        }
    });

    function loadDevicePath(mac) {
        db.ref(`ubicaciones/${mac}`).once('value').then(snapshot => {
            const points = [];
            snapshot.forEach(timeSnap => {
                const { lat, lng } = timeSnap.val();
                points.push([lat, lng]);
            });
            
            if (points.length > 0) {
                deviceLayers[mac] = L.polyline(points, {
                    color: deviceColors[mac],
                    weight: 5,
                    opacity: 0.7
                }).addTo(map);
                
                // Centrar mapa en la ruta
                map.fitBounds(deviceLayers[mac].getBounds());
            }
        });
    }

    function clearDevicePath(mac) {
        if (deviceLayers[mac]) {
            map.removeLayer(deviceLayers[mac]);
            delete deviceLayers[mac];
        }
    }

    document.getElementById('update-interval').addEventListener('click', () => {
        const interval = parseInt(document.getElementById('interval-input').value) * 1000;
        db.ref('config').update({ intervalo_envio: interval })
            .then(() => alert("Intervalo actualizado!"))
            .catch((error) => alert("Error: " + error.message));
    });
}

function getRandomColor() {
    return '#' + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
}