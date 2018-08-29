#include <module/Module.h> // include JAGS module base class
#include <distributions/DBern.h> // include Bernoulli distribution class
#include <functions/ResWagner.h> // include ResWagner function class

namespace jags {
namespace cidlab { // start defining the module namespace

  // Module class
  class CIDLABModule : public Module {
    public:
      CIDLABModule(); // constructor
      ~CIDLABModule(); // destructor
  };

  // Constructor function
  CIDLABModule::CIDLABModule() : Module("cidlab") {
    // insert(new DBern); // inherited function to load objects into JAGS
    insert(new ResWagner);
  }

  // Destructor function
  CIDLABModule::~CIDLABModule() {
    std::vector<Distribution*> const &dvec = distributions();
    for (unsigned int i = 0; i < dvec.size(); ++i) {
      delete dvec[i]; // delete all instantiated distribution objects
    }

    std::vector<Function*> const &fvec = functions();
    for (unsigned int i = 0; i < fvec.size(); ++i) {
      delete fvec[i];
    }
  }

} // end namespace definition
}

jags::cidlab::CIDLABModule _cidlab_module;