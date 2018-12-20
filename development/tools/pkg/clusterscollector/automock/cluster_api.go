// Code generated by mockery v1.0.0. DO NOT EDIT.

package automock

import container "google.golang.org/api/container/v1"
import mock "github.com/stretchr/testify/mock"

// ClusterAPI is an autogenerated mock type for the ClusterAPI type
type ClusterAPI struct {
	mock.Mock
}

// ListClusters provides a mock function with given fields: project
func (_m *ClusterAPI) ListClusters(project string) ([]*container.Cluster, error) {
	ret := _m.Called(project)

	var r0 []*container.Cluster
	if rf, ok := ret.Get(0).(func(string) []*container.Cluster); ok {
		r0 = rf(project)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]*container.Cluster)
		}
	}

	var r1 error
	if rf, ok := ret.Get(1).(func(string) error); ok {
		r1 = rf(project)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// RemoveCluster provides a mock function with given fields: name, project, zone
func (_m *ClusterAPI) RemoveCluster(name string, project string, zone string) error {
	ret := _m.Called(name, project, zone)

	var r0 error
	if rf, ok := ret.Get(0).(func(string, string, string) error); ok {
		r0 = rf(name, project, zone)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}