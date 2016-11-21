using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PosterizerScript : MonoBehaviour {

    Material material;

    public bool antialiasing;

    // Use this for initialization
    void Start () {


    }
	
	// Update is called once per frame
	void Update () {
        //Vector3 ObjectToCamera = camera.transform.position - transform.position;
        //distance = ObjectToCamera.magnitude;
        //calculated = 1 / distance;

        //GetComponent<Renderer>().material.SetVector("_Transform", ObjectToCamera);
        //GetComponent<Renderer>().material.SetFloat("_Distance", distance);

        if (antialiasing) {

            for (int i = 0; i < GetComponent<Renderer>().materials.Length; i++) {
                GetComponent<Renderer>().materials[i].EnableKeyword("ANTIALIASING_ON");
                GetComponent<Renderer>().materials[i].DisableKeyword("ANTIALIASING_OFF");
            }

        } else {

            for (int i = 0; i < GetComponent<Renderer>().materials.Length; i++) {
                GetComponent<Renderer>().materials[i].EnableKeyword("ANTIALIASING_OFF");
                GetComponent<Renderer>().materials[i].DisableKeyword("ANTIALIASING_ON");
            }

        }

    }
}
