#ifdef _WIN32

unsigned int pcthread_get_num_procs() {
  SYSTEM_INFO sysinfo;
  GetSystemInfo(&sysinfo);
  return sysinfo.dwNumberOfProcessors;
}

#else

#include <unistd.h>
#include <pthread.h>

unsigned int pcthread_get_num_procs() {
  return (unsigned int)sysconf(_SC_NPROCESSORS_ONLN);
}

#endif /* _WIN32 */
