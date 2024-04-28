package ghasemiarani.iman.inter_app_communication

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log

class InterReceiver : BroadcastReceiver() {
    companion object {
        fun sendIntent(
            context: Context,
            packageId: String,
            senderPackageId: String,
            type: String,
            id: String?,
            data: HashMap<*, *>?
        ) {
            val intent = Intent("${packageId}.${type.uppercase()}")
            intent.putExtra("event",Bundle().apply {
                putString("packageId", packageId)
                putString("senderPackageId", senderPackageId)
                putString("type", type)
                putString("id", id)
                putSerializable("data", data)
            })

            intent.setPackage(packageId)
            context.sendBroadcast(intent)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val bundle = intent.getBundleExtra("event") ?: return
        val packageId = bundle.getString("packageId") ?: return
        val senderPackageId = bundle.getString("senderPackageId") ?: return
        val type = bundle.getString("type") ?: return
        val id = bundle.getString("id")
        val data = bundle.getSerializable("data") as HashMap<*, *>?

        InterAppCommunicationPlugin.onEvent(bundle)

        when (intent.action) {
            "${context.packageName}.REQUEST" -> {
//                println("Received request with id: $id and data: $data")
            }

            "${context.packageName}.RESPONSE" -> {
//                println("Received response with id: $id and data: $data")
            }

            else -> {
//                println("Received unknown action: ${intent.action}")
            }
        }
    }
}
