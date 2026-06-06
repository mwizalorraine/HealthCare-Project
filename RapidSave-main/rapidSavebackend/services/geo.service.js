const { getDistance, orderByDistance } = require('geolib');

const toGeolib = ([lng, lat]) => ({ latitude: lat, longitude: lng });

const getDistanceMeters = (coordsA, coordsB) =>
  getDistance(toGeolib(coordsA), toGeolib(coordsB));

const getDistanceKm = (coordsA, coordsB) =>
  parseFloat((getDistanceMeters(coordsA, coordsB) / 1000).toFixed(2));

const sortByDistance = (origin, pharmacies) => {
  const mapped = pharmacies.map((p) => ({
    ...p.toObject(),
    _coordinates: toGeolib(p.location.coordinates),
  }));

  return orderByDistance(toGeolib(origin), mapped, (item) => item._coordinates).map(
    ({ _coordinates, ...rest }) => rest
  );
};

const buildNearbyQuery = (lng, lat, radiusKm = 5) => ({
  location: {
    $near: {
      $geometry:    { type: 'Point', coordinates: [lng, lat] },
      $maxDistance: radiusKm * 1000,
    },
  },
});

module.exports = { getDistanceMeters, getDistanceKm, sortByDistance, buildNearbyQuery };