from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import json
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Load model and metadata
print("Loading model and metadata...")
model = joblib.load('accident_prediction_model.pkl')
with open('accident_prone_places.json', 'r') as f:
    accident_prone_data = json.load(f)
with open('feature_names.json', 'r') as f:
    feature_names = json.load(f)
with open('model_metadata.json', 'r') as f:
    model_metadata = json.load(f)

accident_prone_places_set = set([place.lower().strip() for place in accident_prone_data['places']])
print(f"Loaded {len(accident_prone_places_set)} accident-prone areas")

@app.route('/api/check_location', methods=['POST'])
def check_location():
    """
    Check if a barangay is accident-prone
    Expected JSON: {"barangay": "poblacion", "station": "dagupan"}
    """
    try:
        data = request.json
        barangay = data.get('barangay', '').lower().strip()
        station = data.get('station', 'unknown').lower().strip()

        if not barangay:
            return jsonify({'error': 'Barangay name is required'}), 400

        # Create composite key: "barangay, station"
        location_key = f"{barangay}, {station}"

        # Check using composite key
        is_accident_prone = location_key in accident_prone_places_set

        # Get accident statistics for the specific barangay + station combination
        stats = accident_prone_data.get('statistics', {}).get(location_key, {})
        accident_count = stats.get('total_accidents', 0)
        fatal_count = stats.get('fatal_accidents', 0)
        common_offense = stats.get('most_common_offense', 'Unknown')
        
        # Calculate risk level
        if is_accident_prone:
            if fatal_count > 5:
                risk_level = 'CRITICAL'
                confidence = 0.92
            else:
                risk_level = 'HIGH'
                confidence = 0.85
        else:
            risk_level = 'LOW'
            confidence = 0.75
        
        # Create appropriate message
        if is_accident_prone:
            message = f"⚠️ WARNING: {barangay.upper()} is an accident-prone area with {accident_count} recorded incidents!"
            if fatal_count > 0:
                message += f" {fatal_count} fatal accidents recorded."
        else:
            message = f"✓ {barangay.upper()} has low accident risk with {accident_count} incidents recorded."
        
        response = {
            'barangay': barangay.title(),
            'station': station.title(),
            'is_accident_prone': is_accident_prone,
            'accident_count': accident_count,
            'fatal_accidents': fatal_count,
            'risk_level': risk_level,
            'confidence': confidence,
            'common_offense': common_offense,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/safety_tips', methods=['GET'])
def get_safety_tips():
    """Get safety tips for accident-prone areas"""
    risk_level = request.args.get('risk_level', 'HIGH')
    
    general_tips = [
        "🚗 Reduce your speed and stay alert",
        "👀 Watch for pedestrians, motorcycles, and tricycles",
        "🌙 Use headlights even during daytime in high-risk areas",
        "📱 Avoid using mobile phones while driving",
        "⚡ Maintain safe distance from other vehicles",
        "🛑 Obey all traffic signs and signals",
        "☔ Drive extra carefully during rain",
        "🚸 Be extra cautious near schools, markets, and residential areas"
    ]
    
    critical_tips = [
        "🚨 SLOW DOWN IMMEDIATELY - High accident zone",
        "⚠️ Double check for cross traffic at intersections",
        "👮 Follow speed limits strictly",
        "🔦 Ensure all lights are working properly",
        "🛣️ Consider alternative routes if possible"
    ]
    
    if risk_level == 'CRITICAL':
        tips = critical_tips + general_tips
    else:
        tips = general_tips
    
    return jsonify({'tips': tips, 'risk_level': risk_level}), 200

@app.route('/api/alternative_routes', methods=['POST'])
def get_alternative_routes():
    """Suggest alternative routes"""
    data = request.json
    current_barangay = data.get('current_barangay', 'Unknown')
    
    # In production, this would integrate with Google Maps API
    # For now, return generic suggestions
    routes = [
        {
            'route_name': 'Provincial Road Route',
            'description': 'Via main provincial highway',
            'estimated_time': '15 mins',
            'distance': '8.5 km',
            'risk_level': 'LOW',
            'recommended': True
        },
        {
            'route_name': 'Bypass via National Highway',
            'description': 'Longer but safer route',
            'estimated_time': '20 mins',
            'distance': '12.3 km',
            'risk_level': 'LOW',
            'recommended': True
        },
        {
            'route_name': 'Direct Route',
            'description': 'Fastest but through accident-prone area',
            'estimated_time': '10 mins',
            'distance': '6.2 km',
            'risk_level': 'HIGH',
            'recommended': False
        }
    ]
    
    return jsonify({
        'current_barangay': current_barangay,
        'routes': routes,
        'note': 'Please drive carefully regardless of route chosen'
    }), 200

@app.route('/api/statistics', methods=['GET'])
def get_statistics():
    """Get overall statistics"""
    return jsonify({
        'total_places': accident_prone_data['total_places'],
        'accident_prone_count': len(accident_prone_places_set),
        'threshold': accident_prone_data['threshold'],
        'model_accuracy': model_metadata['accuracy'],
        'training_samples': model_metadata['training_samples']
    }), 200

@app.route('/api/barangay_list', methods=['GET'])
def get_barangay_list():
    """Get list of all barangays and their risk status"""
    is_accident_prone_only = request.args.get('accident_prone_only', 'false').lower() == 'true'

    barangay_list = []
    for location_key, stats in accident_prone_data.get('statistics', {}).items():
        if is_accident_prone_only and not stats.get('is_accident_prone', False):
            continue

        barangay_list.append({
            'name': stats.get('barangay', location_key).title(),
            'station': stats.get('station', 'Unknown').title(),
            'is_accident_prone': stats.get('is_accident_prone', False),
            'total_accidents': stats.get('total_accidents', 0),
            'fatal_accidents': stats.get('fatal_accidents', 0)
        })

    # Sort by accident count
    barangay_list.sort(key=lambda x: x['total_accidents'], reverse=True)

    return jsonify({
        'barangays': barangay_list,
        'total_count': len(barangay_list)
    }), 200

@app.route('/api/municipalities', methods=['GET'])
def get_municipalities():
    """Get list of unique municipalities from loaded data"""
    try:
        # Extract unique municipalities/stations from accident data
        municipalities = set()

        # Get municipalities from statistics data
        for stats in accident_prone_data.get('statistics', {}).values():
            station = stats.get('station', '').strip()
            if station:
                municipalities.add(station.title())

        return jsonify({
            'municipalities': sorted(list(municipalities)),
            'total_count': len(municipalities)
        }), 200

    except Exception as e:
        return jsonify({
            'error': str(e),
            'municipalities': [],
            'total_count': 0
        }), 500

@app.route('/api/barangays', methods=['GET'])
def get_barangays_by_municipality():
    """Get list of barangays for a specific municipality"""
    try:
        municipality = request.args.get('municipality', '').lower().strip()

        if not municipality:
            return jsonify({'error': 'Municipality parameter is required'}), 400

        barangays = set()  # Use set to avoid duplicates

        # Get barangays for the specified municipality from statistics
        for location_key, stats in accident_prone_data.get('statistics', {}).items():
            station = stats.get('station', '').lower().strip()
            if station == municipality:
                barangay = stats.get('barangay', '')
                if barangay:
                    barangays.add(barangay.title())

        # Convert to sorted list (alphabetically)
        barangays_list = sorted(list(barangays))

        return jsonify({
            'municipality': municipality.title(),
            'barangays': barangays_list,
            'total_count': len(barangays_list)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e), 'barangays': []}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """API health check"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'model_type': model_metadata['model_type'],
        'model_accuracy': model_metadata['accuracy'],
        'accident_prone_areas_loaded': len(accident_prone_places_set),
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/', methods=['GET'])
def home():
    """API information"""
    return jsonify({
        'service': 'Accident Prone Area Prediction API',
        'version': '1.0.0',
        'endpoints': {
            'POST /api/check_location': 'Check if a barangay is accident-prone',
            'GET /api/safety_tips': 'Get safety tips',
            'POST /api/alternative_routes': 'Get alternative routes',
            'GET /api/statistics': 'Get overall statistics',
            'GET /api/barangay_list': 'Get list of all barangays',
            'GET /api/municipalities': 'Get list of municipalities',
            'GET /api/barangays': 'Get barangays by municipality',
            'GET /api/health': 'Health check'
        }
    }), 200

if __name__ == '__main__':
    print("\n" + "="*60)
    print("ACCIDENT PREDICTION API SERVER")
    print("="*60)
    print(f"\nModel Info:")
    print(f"   Type: {model_metadata['model_type']}")
    print(f"   Accuracy: {model_metadata['accuracy']:.2%}")
    print(f"   Training samples: {model_metadata['training_samples']}")
    print(f"\nLoaded Data:")
    print(f"   Total places: {accident_prone_data['total_places']}")
    print(f"   Accident-prone areas: {len(accident_prone_places_set)}")
    print(f"\nAPI Endpoints:")
    print("   - POST /api/check_location")
    print("   - GET  /api/safety_tips")
    print("   - POST /api/alternative_routes")
    print("   - GET  /api/statistics")
    print("   - GET  /api/barangay_list")
    print("   - GET  /api/municipalities")
    print("   - GET  /api/barangays")
    print("   - GET  /api/health")

    # Get port from environment variable (for production deployment)
    port = int(os.environ.get('PORT', 5000))
    # Get debug mode from environment (default to False for production)
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'

    print(f"\nServer starting on http://0.0.0.0:{port}")
    print(f"Debug mode: {debug_mode}")
    print("="*60 + "\n")

    app.run(host='0.0.0.0', port=port, debug=debug_mode)