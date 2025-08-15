package com.example.fotohora

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

class LocationService : Service() {
    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 1001
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "fotohora_location"
    }

    private lateinit var fusedLocationClient: com.google.android.gms.location.FusedLocationProviderClient
    private var intervalo: Long = 30000
    private val db = FirebaseDatabase.getInstance().reference

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { sendLocationToFirebase(it) }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (checkLocationPermission()) {
            startForegroundService()
        } else {
            stopSelf()
        }
        return START_STICKY
    }

    private fun checkLocationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun startForegroundService() {
        startForeground(NOTIFICATION_ID, createNotification("Recolectando ubicación..."))
        setupFirebaseListeners()
        startLocationUpdates()
    }

    private fun setupFirebaseListeners() {
        db.child("config/intervalo_envio").addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                snapshot.getValue(Long::class.java)?.let {
                    intervalo = it
                    restartLocationUpdates()
                    Log.d("FOTOHORA", "Intervalo actualizado: $intervalo ms")
                }
            }
            override fun onCancelled(error: DatabaseError) {
                Log.e("FOTOHORA", "Error en listener de intervalo: ${error.message}")
            }
        })
    }

    private fun startLocationUpdates() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalo).build()

        try {
            fusedLocationClient.requestLocationUpdates(
                request,
                locationCallback,
                Looper.getMainLooper()
            )
            Log.d("FOTOHORA", "Servicio de ubicación iniciado con intervalo: $intervalo ms")
        } catch (e: SecurityException) {
            Log.e("FOTOHORA", "Error de permisos: ${e.message}")
            stopSelf()
        }
    }

    private fun restartLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            startLocationUpdates()
        } catch (e: Exception) {
            Log.e("FOTOHORA", "Error reiniciando ubicación: ${e.message}")
        }
    }

    private fun sendLocationToFirebase(location: Location) {
        val deviceId = getDeviceId()
        val timestamp = System.currentTimeMillis()

        Log.d("FOTOHORA", "Enviando ubicación: DeviceID=$deviceId, Lat=${location.latitude}, Lng=${location.longitude}")

        // Guardar en histórico
        db.child("ubicaciones/$deviceId/$timestamp").setValue(
            mapOf("lat" to location.latitude, "lng" to location.longitude)
        ).addOnSuccessListener {
            Log.d("FOTOHORA", "Ubicación guardada en histórico")
        }.addOnFailureListener {
            Log.e("FOTOHORA", "Error guardando ubicación", it)
        }

        // Actualizar última ubicación
        db.child("dispositivos/$deviceId/ultima_ubicacion").setValue(
            mapOf(
                "lat" to location.latitude,
                "lng" to location.longitude,
                "timestamp" to timestamp
            )
        ).addOnSuccessListener {
            Log.d("FOTOHORA", "Última ubicación actualizada")
        }.addOnFailureListener {
            Log.e("FOTOHORA", "Error actualizando última ubicación", it)
        }
    }

    private fun getDeviceId(): String {
        return Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ANDROID_ID
        ) ?: "unknown_device"
    }

    private fun createNotification(text: String): Notification {
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Servicio de Ubicación Fotohora")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Service",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        return builder.build()
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            Log.d("FOTOHORA", "Servicio de ubicación detenido")
        } catch (e: Exception) {
            Log.e("FOTOHORA", "Error deteniendo servicio", e)
        }
    }
}