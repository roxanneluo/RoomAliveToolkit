using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Pan : MonoBehaviour {
	public Vector2 panRadius;
	public Vector2 v;
	public Vector3 startPos;
	// Use this for initialization
	void Start () {
		startPos = transform.position;
		transform.position = new Vector3 (startPos.x - panRadius.x,
			startPos.y - panRadius.y, startPos.z);
	}
	
	// Update is called once per frame
	void Update () {
		if (transform.position.y > startPos.y + panRadius.y) {
			transform.position = new Vector3 (startPos.x - panRadius.x,
				startPos.y - panRadius.y, startPos.z);
			return;
		}

		if (transform.position.x > startPos.x + panRadius.x ||
			transform.position.x < startPos.x - panRadius.x) {
			transform.position += new Vector3 (0, v.y, 0);
			v.x = -v.x;
		}

		Vector3 vx = new Vector3 (v.x, 0, 0);
		transform.position += vx;
	}
}
