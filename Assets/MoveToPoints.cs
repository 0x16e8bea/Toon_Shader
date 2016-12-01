using System.Collections.Generic;
using UnityEngine;

//moves object along a series of waypoints, useful for moving platforms or hazards
//this class adds a kinematic rigidbody so the moving object will push other rigidbodies whilst moving

namespace Assets.Scripts.Platforms {
    [RequireComponent(typeof(Rigidbody))]
    public class MoveToPoints : MonoBehaviour {
        public enum Type {
            PlayOnce,
            Loop,
            PingPong
        }

        private readonly int _numberOfWaypointsInCircle = 32;
        private readonly List<Vector3> _waypoints = new List<Vector3>();

        private float _arrivalTime;
        private int _currentWp;
        private Rigidbody _rigidbody;
        public float Delay; //how long to wait at each waypoint
        public bool Forward = true, Arrived;
        public Type MovementType;
        //stop at final waypoint, loop through _waypoints or move back n forth along _waypoints

        public float Radius;

        public bool SetUpACircleWaypoint = false, UseRandomSpeed = false;

        public float Speed, MaxSpeed, MinSpeed; //how fast to move

        //setup
        private void Awake() {
            //add kinematic _rigidbody
            if (!GetComponent<Rigidbody>()) {
                _rigidbody = gameObject.AddComponent<Rigidbody>();
                _rigidbody.isKinematic = true;
                _rigidbody.useGravity = false;
                _rigidbody.interpolation = RigidbodyInterpolation.Interpolate;
            }

            if (UseRandomSpeed)
                Speed = Random.Range(MinSpeed, MaxSpeed);


            if (SetUpACircleWaypoint)
                for (var i = 0; i < _numberOfWaypointsInCircle; i++) {
                    var g = new GameObject("Waypoint" + " " + i);
                    g.tag = "Waypoint";
                    var direction = Forward ? 1 : -1;
                    var angle = direction*i*Mathf.PI*2/_numberOfWaypointsInCircle;
                    var pos = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle))*Radius;
                    g.transform.position = transform.position + pos;
                    g.transform.parent = transform;
                }
            //get child _waypoints, then detach them (so object can move without moving _waypoints)
            foreach (Transform child in transform)
                if (child.tag == "Waypoint") {
                    _waypoints.Add(child.position);
                    child.gameObject.SetActive(false);
                }

            if (_waypoints.Count == 0)
                Debug.LogError(
                    "No _waypoints found for 'MoveToPoints' script. To add _waypoints: add child gameObjects with the tag 'Waypoint'",
                    transform);

            if (_waypoints.Count != 0)
                transform.position = _waypoints[0];
        }

        //if we've arrived at waypoint, get the next one
        private void Update() {
            if (_waypoints.Count > 0)
                if (!Arrived) {
                    if (Vector3.Distance(transform.position, _waypoints[_currentWp]) < 0.3f) {
                        _arrivalTime = Time.time;
                        Arrived = true;
                    }
                } else {
                    if (Time.time > _arrivalTime + Delay) {
                        GetNextWp();
                        Arrived = false;
                    }
                }
        }

        //move object toward waypoint
        private void FixedUpdate() {
            if (!Arrived && (_waypoints.Count > 0)) {
                var direction = _waypoints[_currentWp] - transform.position;
                GetComponent<Rigidbody>()
                    .MovePosition(transform.position + direction.normalized*Speed*Time.fixedDeltaTime);
            }
        }

        //get the next waypoint
        private void GetNextWp() {
            if (MovementType == Type.PlayOnce) {
                _currentWp++;
                if (_currentWp == _waypoints.Count)
                    enabled = false;
            }

            if (MovementType == Type.Loop)
                _currentWp = _currentWp == _waypoints.Count - 1 ? 0 : _currentWp += 1;

            if (MovementType == Type.PingPong) {
                if (_currentWp == _waypoints.Count - 1)
                    Forward = false;
                else if (_currentWp == 0)
                    Forward = true;
                _currentWp = Forward ? _currentWp += 1 : _currentWp -= 1;
            }
        }

        //draw gizmo spheres for _waypoints
        private void OnDrawGizmos() {
            Gizmos.color = Color.cyan;

            if (Application.isPlaying) {
                foreach (var child in _waypoints)
                    Gizmos.DrawSphere(child, .7f);
            } else {
                if (!SetUpACircleWaypoint)
                    foreach (Transform child in transform)
                        Gizmos.DrawSphere(child.position, .7f);
                else
                    for (var i = 0; i < _numberOfWaypointsInCircle; i++) {
                        var angle = i*Mathf.PI*2/_numberOfWaypointsInCircle;
                        var pos = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle))*Radius;
                        Gizmos.DrawSphere(transform.position + pos, .7f)
                            ;
                    }
            }
        }
    }
}

/* NOTE: remember to tag object as "Moving Platform" if you want the player to be able to stand and move on it
 * for waypoints, simple use an empty gameObject parented the the object. Tag it "Waypoint", and number them in order */