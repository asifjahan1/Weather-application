// ignore_for_file: unused_local_variable, unused_element

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State with WidgetsBindingObserver {
  Position? _position;
  late Map<String, dynamic> _weatherMap;
  late Map<String, dynamic> _forecastMap;
  late String _locationName = '';
  late String _areaName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _determinePosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition();
      _fetchWeatherData();
      _getLocationName(_position!.latitude, _position!.longitude);
    } catch (e) {
      _showErrorDialog('Error fetching location: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    const String apiKey =
        'IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ';
    final double latitude = _position!.latitude;
    final double longitude = _position!.longitude;

    String weatherUrl =
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";
    String forecastUrl =
        "https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=metric&appid=f92bf340ade13c087f6334ed434f9761&fbclid=IwAR0vlebaouEmURClRdtuWEg7qeBOdbDxmQ5HM9JDJL_mj5uDS7xqy4kCGTQ";

    try {
      final http.Response weatherResponse =
          await http.get(Uri.parse(weatherUrl));
      final http.Response forecastResponse =
          await http.get(Uri.parse(forecastUrl));

      _weatherMap = Map<String, dynamic>.from(jsonDecode(weatherResponse.body));
      _forecastMap =
          Map<String, dynamic>.from(jsonDecode(forecastResponse.body));

      setState(() {});
    } catch (e) {
      _showErrorDialog('Error fetching weather data: $e');
    }
  }

  Future<void> _getAreaName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String region = placemark.administrativeArea ?? placemark.country ?? '';
        setState(() {
          _areaName = region;
        });
      }
    } catch (e) {
      print('Error getting region name: $e');
    }
  }

  Future<void> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            '';
        setState(() {
          _locationName = city;
        });
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF738BE3),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_locationName.isNotEmpty)
                  Text(
                    _locationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (_position != null)
              Column(
                children: [
                  Text(
                    '${_position!.latitude}, ${_position!.longitude}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (_areaName.isNotEmpty)
                    Text(
                      'Area: $_areaName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _determinePosition();
    }
  }
}
