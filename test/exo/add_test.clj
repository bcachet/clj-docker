(ns exo.add-test
  (:require [clojure.test :refer [deftest is]]
            [exo.add :refer [sum]]))


(deftest sum-all-things
  (is (= (sum 1 2 3)
         6)))


(deftest ^:integration sum-all-things-in-integration
  (is (= (sum 1 1)
         2)))

