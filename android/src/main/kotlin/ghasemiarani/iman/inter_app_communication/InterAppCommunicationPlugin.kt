package ghasemiarani.iman.inter_app_communication

import android.annotation.SuppressLint
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.ref.WeakReference

/** InterAppCommunicationPlugin */
class InterAppCommunicationPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    companion object {

        @SuppressLint("StaticFieldLeak")
        private lateinit var instance: InterAppCommunicationPlugin

        private val methodChannels = mutableMapOf<BinaryMessenger, MethodChannel>()
        private val eventChannels = mutableMapOf<BinaryMessenger, EventChannel>()
        private val eventHandlers = mutableListOf<WeakReference<EventCallbackHandler>>()

        private fun sendEvent(event: Map<String, Any>) {
            eventHandlers.forEach {
                it.get()?.send(event)
            }
        }

        fun sharePluginWithRegister(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) =
            initSharedInstance(
                flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger
            )

        private fun initSharedInstance(context: Context, binaryMessenger: BinaryMessenger) {
            if (!::instance.isInitialized) {
                instance = InterAppCommunicationPlugin()
                instance.context = context
            }

            val channel = MethodChannel(binaryMessenger, "inter_app_communication")
            methodChannels[binaryMessenger] = channel
            channel.setMethodCallHandler(instance)

            val events = EventChannel(binaryMessenger, "inter_app_communication.event")
            eventChannels[binaryMessenger] = events
            val handler = EventCallbackHandler()
            eventHandlers.add(WeakReference(handler))
            events.setStreamHandler(handler)
        }

        fun onEvent(event: Bundle) {
            sendEvent(
                mapOf(
                    "packageId" to event.getString("packageId") as String,
                    "senderPackageId" to event.getString("senderPackageId") as String,
                    "type" to event.getString("type") as String,
                    "id" to event.getString("id") as String,
                    "data" to (event.getSerializable("data") as HashMap<*, *>? ?: hashMapOf<String, Any>())
                )
            )
        }

        fun onError(error: String) {
            sendEvent(
                mapOf(
                    "error" to error
                )
            )
        }

    }

    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) =
        sharePluginWithRegister(flutterPluginBinding)

    override fun onMethodCall(call: MethodCall, result: Result) = when {
        call.method == "sendDataToApp" -> {
            val args = call.arguments as Map<*, *>?
            try {
                val packageId = args?.get("packageId") as String
                val senderPackageId = args["senderPackageId"] as String? ?: context.packageName
                val type = args["type"] as String
                val id = args["id"] as String?
                val data = args["data"] as HashMap<*, *>?

                InterReceiver.sendIntent(context, packageId, senderPackageId, type, id, data)

                result.success("Data sent to app with $packageId")
            } catch (e: Exception) {
                result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
            }

        }

        else -> result.notImplemented()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannels.remove(binding.binaryMessenger)?.setMethodCallHandler(null)
        eventChannels.remove(binding.binaryMessenger)?.setStreamHandler(null)
    }


    class EventCallbackHandler : EventChannel.StreamHandler {

        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            eventSink = sink
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }

        fun send(event: Map<String, Any>) {
            Handler(Looper.getMainLooper()).post { eventSink?.success(event) }
        }
    }

}
