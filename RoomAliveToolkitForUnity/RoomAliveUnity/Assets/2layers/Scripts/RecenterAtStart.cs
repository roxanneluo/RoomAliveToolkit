using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RecenterAtStart : MonoBehaviour {
	public GameObject obj;
	// Use this for initialization
	void Start () {
		Vector3 start_pos = transform.position;
		obj.transform.position = start_pos;
	}
}
