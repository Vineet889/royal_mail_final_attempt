package com.example.your_app

import android.webkit.WebView
import android.webkit.JavascriptInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AddressNowPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var webView: WebView
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "address_now_channel")
        channel.setMethodCallHandler(this)
        
        webView = WebView(binding.applicationContext)
        webView.settings.javaScriptEnabled = true
        webView.addJavascriptInterface(AddressNowInterface(), "AddressNowFlutter")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeAddressNow" -> {
                val apiKey = call.argument<String>("apiKey")
                initializeAddressNow(apiKey!!, result)
            }
            "findAddresses" -> {
                val search = call.argument<String>("search")
                findAddresses(search!!, result)
            }
            "retrieveAddress" -> {
                val id = call.argument<String>("id")
                retrieveAddress(id!!, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun initializeAddressNow(apiKey: String, result: Result) {
        val js = """
            <script src="http://api.addressnow.co.uk/js/addressnow-2.20.min.js?key=$apiKey"></script>
            <script>
                var addressNow = new pca.Address();
                addressNow.listen("load", function() {
                    AddressNowFlutter.onInitialized();
                });
            </script>
        """
        webView.loadDataWithBaseURL(null, js, "text/html", "UTF-8", null)
        pendingResult = result
    }

    private fun findAddresses(search: String, result: Result) {
        pendingResult = result
        webView.evaluateJavascript("""
            addressNow.find('$search').then(function(suggestions) {
                AddressNowFlutter.onAddressSuggestions(JSON.stringify(suggestions));
            });
        """, null)
    }

    private fun retrieveAddress(id: String, result: Result) {
        pendingResult = result
        webView.evaluateJavascript("""
            addressNow.retrieve('$id').then(function(address) {
                AddressNowFlutter.onAddressRetrieved(JSON.stringify(address));
            });
        """, null)
    }

    inner class AddressNowInterface {
        @JavascriptInterface
        fun onInitialized() {
            pendingResult?.success(null)
            pendingResult = null
        }

        @JavascriptInterface
        fun onAddressSuggestions(suggestionsJson: String) {
            pendingResult?.success(suggestionsJson)
            pendingResult = null
        }

        @JavascriptInterface
        fun onAddressRetrieved(addressJson: String) {
            pendingResult?.success(addressJson)
            pendingResult = null
        }
    }
} 